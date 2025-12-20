//
//  AuthenticationViewModel.swift
//  GoogleCalendarAPIDemo
//
//  Created by Goel, Pratik on 20/11/22.
//

private let AUTHORIZER_KEY: String = "hoge"

import Foundation
import AppAuth
import GTMAppAuth
import GoogleAPIClientForREST_Calendar
import CoreSpotlight
import MobileCoreServices

enum SignInState {
    case signedIn
    case signedOut
}

enum CalendarError: Error {
    case calendarServiceError
    case networkError
}

struct CalendarColorDefinitons: Codable {
    let calendar: [Int : ColorDefinition]
    let event: [Int : ColorDefinition]
}

struct ColorDefinition: Codable {
    let background: String
    let foreground: String
}

private let CALENDAR_SCOPES: [String] = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/calendar.events.readonly",
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
    "https://www.googleapis.com/auth/admin.directory.resource.calendar.readonly",
]

final class AuthenticationViewModel: ObservableObject, @unchecked Sendable {

    @Published var state: SignInState = .signedOut
    @Published var calendarService: GTLRCalendarService? = nil
    @Published var calendarList: GTLRCalendar_CalendarList = GTLRCalendar_CalendarList()
    @Published var calendarListItems: [GTLRCalendar_CalendarListEntry] = [] {
        didSet {
            addCalendarListToSpotlight()
        }
    }
    @Published var calendarColorDefinitions: CalendarColorDefinitons?
    @Published var allEvents : [String: [GTLRCalendar_Event]] = [:] {
        didSet {
            addCalendarEventsToSpotlight()
        }
    }

    private var authorization: GTMAppAuthFetcherAuthorization? = nil
    private static let clientID: String = getClientID()
    private let configuration = GTMAppAuthFetcherAuthorization.configurationForGoogle()

    private static func getDictFromPlist() -> NSDictionary {
        guard let path = Bundle.main.path(forResource: "GoogleInfo", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) else {
            return [:]
        }
        return dict
    }

    private static func getClientID() -> String {
        let dict = Self.getDictFromPlist()
        return (dict["CLIENT_ID"] as? String) ?? ""
    }

    private static func getReverseClientID() -> String {
        let dict = Self.getDictFromPlist()
        return (dict["REVERSED_CLIENT_ID"] as? String) ?? ""
    }

    @MainActor func signIn() {
        if let _ = GTMAppAuthFetcherAuthorization.init(fromKeychainForName: AUTHORIZER_KEY) {
            authenticateUser()
        } else {
            // since swiftui has no viewcontroller, we use uiapplication window to check for the root vc
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }

            let request = OIDAuthorizationRequest.init(
                configuration: configuration,
                clientId: Self.clientID,
                scopes: CALENDAR_SCOPES,
                redirectURL: URL.init(string: "\(Self.getReverseClientID()):/oauthredirect")!,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil
            )
            let _ = OIDAuthState.authState(
                byPresenting: request,
                presenting: rootViewController,
                callback: { (authState, error) in
                    if let error {
                        print("[ERROR] \(error)")
                        self.state = .signedOut
                        return
                    } else {
                        if let authState {
                            print("Authorization succeeded: \(authState)")
                            self.authorization = GTMAppAuthFetcherAuthorization.init(authState: authState)
                            GTMAppAuthFetcherAuthorization.save(self.authorization!, toKeychainForName: AUTHORIZER_KEY)
                        }
                    }
                    self.authenticateUser()
                }
            )
        }
    }

    func authenticateUser() {
        state = .signedIn
        getCalendarService()
        fetchData()
    }

    func fetchData() {
        self.getCalendarList()
        self.getCalendarColors()
        var timer = Timer()
        switch state {
        case .signedIn:
            timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { _ in
                self.getCalendarList()
                self.getCalendarColors()
            })
        case .signedOut:
            timer.invalidate()
        }
    }

    func signOut() {
        GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: AUTHORIZER_KEY)
        state = .signedOut
    }

    func getCalendarService() {
        let service = GTLRCalendarService()
        service.shouldFetchNextPages = true
        service.isRetryEnabled = true
        service.maxRetryInterval = 15
        service.authorizer = GTMAppAuthFetcherAuthorization.init(fromKeychainForName: AUTHORIZER_KEY)
        self.calendarService = service
    }

    func getCalendarColors() {
        guard let calendarService = self.calendarService else { return }

        let colorListQuery = GTLRCalendarQuery_ColorsGet.query()

        _ = calendarService.executeQuery(colorListQuery) { (_, colorList, error) in
            guard error == nil, let colorList = colorList as? GTLRCalendar_Colors else { return }

            // Fetch all calendar color definitions
            do {
                self.calendarColorDefinitions = try JSONDecoder().decode(CalendarColorDefinitons.self, from: Data(colorList.jsonString().utf8))
            } catch {
                print(error)
            }
        }
    }

    func getCalendarList() {
        guard let calendarService = self.calendarService else { return }

        let calendarListQuery = GTLRCalendarQuery_CalendarListList.query()

        _ = calendarService.executeQuery(calendarListQuery) { (_, calendarList, error) in
            guard error == nil, let calendarList = (calendarList) as? GTLRCalendar_CalendarList else { return }

            self.calendarList = calendarList

            // check for nil or no calendars
            guard let calendarListItems = calendarList.items, calendarListItems.count > 0 else { return }

            // Fetch all calendar items
            self.calendarListItems = calendarListItems as [GTLRCalendar_CalendarListEntry]

            // Fetch all calendar events for calendar items
            for item in calendarListItems {
                self.getEventList(for: item.identifier ?? "primary") { result in
                    switch result {
                    case .success((let events)):
                        let id = item.identifier
                        // if email needed c.f. https://qiita.com/ryokkkke/items/4c3da87b50d7a298e604
                        //                        let user = GIDSignIn.sharedInstance.currentUser
                        //                        if let email = user?.profile?.email {
                        //                            if let idx = id, idx == email {
                        //                                id = "primary"
                        //                            }
                        //                        }
                        self.allEvents[id ?? "primary"] = events
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }

    func getEventList(for calendarId: String, showDeleted: Bool = false, showHidden: Bool = false, startDateTime: GTLRDateTime? = nil, endDateTime: GTLRDateTime? = nil, completion: @escaping (Result<[GTLRCalendar_Event], Error>) -> Void) {
        guard let service = self.calendarService else {
            completion(.failure(CalendarError.calendarServiceError))
            return
        }

        let eventsListQuery = GTLRCalendarQuery_EventsList.query(withCalendarId: calendarId)
        eventsListQuery.timeMin = startDateTime
        eventsListQuery.timeMax = endDateTime
        eventsListQuery.showDeleted = showDeleted

        _ = service.executeQuery(eventsListQuery) { (_, result, error) in
            guard error == nil, let items = (result as? GTLRCalendar_Events)?.items else {
                completion(.failure(CalendarError.networkError))
                return
            }
            completion(.success(items))
        }
    }
}

extension AuthenticationViewModel {

    func addCalendarListToSpotlight() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let domainIdentifier = "\(bundleID).calendarList"
        let searchableItems = calendarListItems.map { entity -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.containerDisplayName = "Calendar"
            attributeSet.title = entity.summary
            attributeSet.contentDescription = entity.descriptionProperty
            attributeSet.relatedUniqueIdentifier = entity.identifier
            return CSSearchableItem(uniqueIdentifier: entity.identifier, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
        }
        removeFromSpotlight(domainIdentifier)
        addToSpotlight(searchableItems)
    }

    func addCalendarEventsToSpotlight() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let domainIdentifier = "\(bundleID).calendarEvents"
        let events = allEvents.flatMap { $0.value }
        let searchableItems = events.map { entity -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.containerDisplayName = "Event"
            attributeSet.title = entity.summary
            attributeSet.contentDescription = entity.descriptionProperty
            attributeSet.relatedUniqueIdentifier = entity.identifier
            attributeSet.url = URL(string: entity.hangoutLink ?? "")
            attributeSet.startDate = entity.start?.dateTime?.date ?? Date.now
            attributeSet.endDate = entity.end?.dateTime?.date ?? Date.now
            return CSSearchableItem(uniqueIdentifier: entity.identifier, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
        }
        removeFromSpotlight(domainIdentifier)
        addToSpotlight(searchableItems)
    }

    func addToSpotlight( _ searchableItems: [CSSearchableItem]) {
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                print(error)
            }
        }
    }

    func removeFromSpotlight(_ domainIdentifier: String) {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
        { (error: Error?) -> Void in
            if let error = error {
                print("Remove error: \(error.localizedDescription)")
            }
        }
    }

    func stringArrayToData(stringArray: [String]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: stringArray, options: [])
    }

    func dataToStringArray(data: Data) -> [String]? {
        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String]
    }
}
