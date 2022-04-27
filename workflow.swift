#!/usr/bin/env swift

import Foundation

// MARK: Workflow Protocol

protocol Workflow {
  
  /// original result list
  var items: [AlfredItem] { get }
  
  /// error message when error occored
  var errorMessage: AlfredItem? { get }
  
  /// message when items is empty
  var emptyMessage: AlfredItem { get }

  func run()
}

// MARK: Alfred Structs

struct AlfredResult: Codable {
  let items: [AlfredItem]
}

struct AlfredItem: Codable {
  var title: String
  var subtitle: String
  var match: String?
  var arg: String?
  var mods: AlfredMods?
}

struct AlfredMods: Codable {
  var cmd: AlfredItemModItem?
  var alt:AlfredItemModItem?
}

struct AlfredItemModItem: Codable {
  var valid: Bool
  var arg: String
  var subtitle: String
}


// MARK: pretty print for Encodable

extension Encodable {
  func prettyPrint() {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    guard let data = try? encoder.encode(self) else { return }
    print(String(data: data, encoding: .utf8)!)
  }
}

// MARK: convert AlfredItem to AlfredResult

extension AlfredItem {
  func toAlfredResult() -> AlfredResult {
    return AlfredResult(items: [self])
  }
}

extension Array where Element == AlfredItem {
  func toAlfredResult() -> AlfredResult {
    return AlfredResult(items: self)
  }
}

// MARK: string fuzzy search
//  fork from https://github.com/khoi/fuzzy-swift/blob/master/Sources/Fuzzy/Fuzzy.swift

extension String {
  func fuzzySearch(_ needle: String) -> Bool {
    guard needle.count <= self.count else {
      return false
    }
    
    if needle == self {
      return true
    }
    
    var needleIdx = needle.startIndex
    var haystackIdx = self.startIndex
    
    while needleIdx != needle.endIndex {
      if haystackIdx == self.endIndex {
        return false
      }
      if needle[needleIdx] == self[haystackIdx] {
        needleIdx = needle.index(after: needleIdx)
      }
      haystackIdx = self.index(after: haystackIdx)
    }
    return true
  }
}

// MARK: filter func for Workflow

extension Workflow {
  func filter(by query: String) -> [AlfredItem] {
    guard !query.isEmpty else {
      return items
    }
    return items.filter { $0.title.fuzzySearch(query) }
  }
}

// MARK: default run implements for Workflow

extension Workflow {
  var queryArg: String {
    CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
  }
  
  var emptyMessage: AlfredItem {
    AlfredItem(title: "Nothing found", subtitle: "Please try another thing")
  }

  func run() {
    if let errorMessage = errorMessage {
      errorMessage.toAlfredResult().prettyPrint()
      return
    }
    guard !items.isEmpty else {
      emptyMessage.toAlfredResult().prettyPrint()
      return
    }
    filter(by: queryArg).toAlfredResult().prettyPrint()
  }
}


// MARK: SourceTree Workflow

class SourceTree: Workflow {
  var errorMessage: AlfredItem?
  var items: [AlfredItem]
  var emptyMessage = AlfredItem(title: "Your SourceTree Bookmark Is Empty ", subtitle: "Please add repos to SourceTree first")
  init() {
    guard let data = try? Data(contentsOf: Self.plistPath) else {
      errorMessage = AlfredItem(title: "SourceTree not installed", subtitle: "Press enter to open SourceTree homepage and download it", arg: "open \"https://sourcetreeapp.com/\"")
      items = []
      return
    }
    
    do {
      let parsed = try PropertyListDecoder().decode(SourceTreePlist.self, from: data)
      items = parsed.toAlfredItems()
    } catch  {
      items = []
      errorMessage = Self.getErrorMessage(error)
    }
  }
  
  static func getErrorMessage(_ error: Error) -> AlfredItem {
    let githubNewIssueUrl = "https://github.com/oe/sourcetree-alfred-workflow/issues/new"
    var urlComponents = URLComponents(string: githubNewIssueUrl)!
    let issueBody = """
      error message:
      \(error.localizedDescription)
      
      environment info:
      macOS version: [pleaase fill your version]
      swift version: [run `swift --version` to get its version]
      """
    let queryItems = [
      URLQueryItem(name: "title", value: "SourceTree plist parse error"),
      URLQueryItem(name: "body", value: issueBody)
    ]
    if urlComponents.queryItems == nil {
      urlComponents.queryItems = []
    }
    urlComponents.queryItems!.append(contentsOf: queryItems)
    return AlfredItem(
      title: "Error occurred",
      subtitle: "Press enter to open github and report an issue to me",
      arg: "open \"\(urlComponents.url?.absoluteString ?? githubNewIssueUrl)\""
    )
  }

  /** SourceTree browser.plist path  */
  static var plistPath: URL {
    let url = FileManager.default.homeDirectoryForCurrentUser
    return url.appendingPathComponent("Library/Application Support/SourceTree/browser.plist")
  }
}

// MARK: SourceTree Plist

extension SourceTree {
  struct SourceTreePlist: Codable {
    let version: Int
    let objects: [String]
    
    enum CodingKeys: String, CodingKey {
      case version = "$version"
      case objects = "$objects"
    }
  }
}

// MARK: Decode SourceTree Plist then parse to Alfred struct

extension SourceTree.SourceTreePlist {
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    version = try container.decode(Int.self, forKey: .version)
    
    var objectsContainer = try container.nestedUnkeyedContainer(forKey: .objects)
    var objects: [String] = []
    while !objectsContainer.isAtEnd {
      if let value = try? objectsContainer.decode(String.self) {
        objects.append(value)
      } else {
        try objectsContainer.skip()
      }
    }
    self.objects = objects
  }
  
  func toAlfredItems() -> [AlfredItem] {
    var namePathGroups: [(name: String, path: String)] = []
    var name = ""
    objects.forEach { str in
      if str.starts(with: "/") {
        if name.isEmpty {
          return
        }
        namePathGroups.append((name: name, path: str))
        name = ""
      } else {
        name = str
      }
    }
    
    return namePathGroups.map { (name, path) in
      let mod = AlfredItemModItem(valid: true, arg: "open \"\(path)\"", subtitle: "Reveal in Finder")
      return AlfredItem(title: name, subtitle: path, arg: path, mods: AlfredMods(cmd: mod))
    }
  }
}

/**
 * add skip to unkeyed container due to this missing feature in Swift
 * https://forums.swift.org/t/pitch-unkeyeddecodingcontainer-movenext-to-skip-items-in-deserialization/22151/12
 */
struct Empty: Decodable { }
extension UnkeyedDecodingContainer {
  public mutating func skip() throws {
    _ = try decode(Empty.self)
  }
}

SourceTree().run()
