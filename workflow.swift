#!/usr/bin/env swift

import Foundation

// MARK: Workflow Protocol

class Workflow {
  
  /// original result list
  var items: [AlfredItem] = []
  
  /// error message when error occored
  var errorMessage: AlfredItem?
  
  /// message when items is empty
  var emptyMessage: AlfredItem = AlfredItem(title: "Nothing found", subtitle: "Please try another thing")

  var queryArg: String {
    CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
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
  
  /// detect current machine chip arch
  ///   reference: https://stackoverflow.com/questions/69624731/programmatically-detect-apple-silicon-vs-intel-cpu-in-a-mac-app-at-runtime
  // static var isAppleChip: Bool = {
  //   var sysInfo = utsname()
  //   let retVal = uname(&sysInfo)
    
  //   guard retVal == EXIT_SUCCESS else { return false }
    
  //   return String(cString: &sysInfo.machine.0, encoding: .utf8) == "arm64"
  // }()
  
  /// detect whether workflow is using as a swift script
  ///   false for binay
  static var isScript: Bool = {
    let env = ProcessInfo.processInfo.environment
    return env["LIBRARY_PATH"] != nil && env["SDKROOT"] != nil
  }()
}

// MARK: Alfred Structs

extension Workflow {  
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

extension Workflow.AlfredItem {
  func toAlfredResult() -> Workflow.AlfredResult {
    return Workflow.AlfredResult(items: [self])
  }
}

extension Array where Element == Workflow.AlfredItem {
  func toAlfredResult() -> Workflow.AlfredResult {
    return Workflow.AlfredResult(items: self)
  }
}

// MARK: string fuzzy search
//  fork from https://github.com/khoi/fuzzy-swift/blob/master/Sources/Fuzzy/Fuzzy.swift

extension String {
  /// fuzzySearch string
  ///   return matching weight, 0 for not match, bigger for less match
  func fuzzySearch(_ needle: String) -> Int {
    var weight = 1
    guard needle.count <= self.count else {
      return 0
    }
    
    
    if needle == self {
      return weight
    }
    
    var needleIdx = needle.startIndex
    var haystackIdx = self.startIndex
    
    while needleIdx != needle.endIndex {
      if haystackIdx == self.endIndex {
        return 0
      }
      // compare ignore case and diacritic
      if String(needle[needleIdx])
          .compare(String(self[haystackIdx]), options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame  {
        needleIdx = needle.index(after: needleIdx)
      } else {
        weight += 1
      }
      haystackIdx = self.index(after: haystackIdx)
    }
    return weight
  }
}

// MARK: filter func for Workflow

extension Workflow {
  func filter(by query: String) -> [AlfredItem] {
    guard !query.isEmpty else {
      return items
    }
    return items
      .map( { ($0, $0.title.fuzzySearch(query)) })
      .filter({ $0.1 > 0 })
      .sorted(by: { $0.1 < $1.1 } )
      .map( { $0.0 } )
  }
}

// MARK: SourceTree Workflow implements

class SourceTree: Workflow {
  override init() {
    super.init()

    emptyMessage = AlfredItem(title: "Your SourceTree Bookmark Is Empty ", subtitle: "Please add repos to SourceTree first")

    guard Self.isSourceTreeInstalled() else {
      errorMessage = AlfredItem(title: "SourceTree not installed", subtitle: "Press enter to open SourceTree homepage and download it", arg: "open \"https://sourcetreeapp.com/\"")
      return
    }
    guard let data = try? Data(contentsOf: Self.plistPath) else {
      errorMessage = emptyMessage
      return
    }
    
    do {
      let parsed = try PropertyListDecoder().decode(SourceTreePlist.self, from: data)
      items = parsed.toAlfredItems()
    } catch  {
      errorMessage = Self.getErrorMessage(error)
    }
  }
  
  override func run() {
    let query = queryArg
    if let errorMessage = errorMessage {
      errorMessage.toAlfredResult().prettyPrint()
      return
    }
    guard !items.isEmpty else {
      emptyMessage.toAlfredResult().prettyPrint()
      return
    }
    var list = filter(by: query)
    var destFile = #file
    // remove the possible extension
    destFile = destFile.replacingOccurrences(of: ".swift", with: "")
    let sourceFile = "\(destFile).swift"

    let compileScript = AlfredItem(
            title: "✈️Compile workflow script",
            subtitle: "Compile workflow script to binary to speed up its response time",
            arg: "swiftc \"\(sourceFile)\" -O -o \"\(destFile)\""
          )
    
    /* if Self.isScript {
      list.insert(compileScript, at: 0)
    } else */if query == "$compile" {
      list.append(compileScript)
    }
    list.toAlfredResult().prettyPrint()
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

  static func isSourceTreeInstalled() -> Bool {
    return FileManager.default.fileExists(atPath: "/Applications/SourceTree.app")
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
  
  func toAlfredItems() -> [Workflow.AlfredItem] {
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
      let alt = Workflow.AlfredItemModItem(valid: true, arg: "open \"\(path)\"", subtitle: "Reveal in Finder")
      // default using `code` aka VS Code to open project
      let editCli = Self.parseEditorCliConfig(with: path)
      let cmd = Workflow.AlfredItemModItem(valid: true, arg: "\(editCli) \"\(path)\"", subtitle: "Open in code editor")
      return Workflow.AlfredItem(title: name, subtitle: path, arg: path, mods: Workflow.AlfredMods(cmd: cmd, alt: alt))
    }
  }

  // parse configurations
  // support comments(start with #)
  private static let editConfigs: [(cli: String, extensions: [String])] = {
    let editorCli = ProcessInfo.processInfo.environment["EDITOR_CLI"] ?? "code"
    let defaultEditorCliConfig = """
    \(editorCli)=*
    """

    let editorCliConfig = ProcessInfo.processInfo.environment["EDITOR_CLI_CONFIG"] ?? defaultEditorCliConfig

    let lines = editorCliConfig.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      // remove empty lines and comments(start with #)
      .filter { !$0.starts(with: "#") && !$0.isEmpty }

    let components = lines.map { $0.components(separatedBy: "=") }
      .filter { $0.count == 2 }

    return components.map {
        // sanitize cli and extensions
        let cli = $0[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let exts = $0[1].trimmingCharacters(in: .whitespacesAndNewlines)
          .components(separatedBy: ",")
          // lowercase for case insensitive compare
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
          .filter { !$0.isEmpty }

        return (cli, exts)
      }
      .filter { !$0.1.isEmpty }
  }()

  private static let defaultEditorCli: String = {
    for (cli, extensions) in editConfigs {
      if extensions[0] == "*" {
        return cli
      }
    }
    // if we didn't find anything then we just return "code"
    return "code"
  }()

  private static func parseEditorCliConfig(with path: String) -> String {
    // cache enumerated files
    var files: [String] = []

    for (cli, extensions) in editConfigs {
      if extensions[0] == "*" {
        return cli
      }

      if !files.isEmpty {
        for file in files {
          if extensions.contains(where: { file.hasSuffix($0) }) {
            return cli
          }
        }
        continue
      }

      let fileManager = FileManager.default
      let enumerator = fileManager.enumerator(atPath: path)

      while let element = enumerator?.nextObject() as? String {
        // search with lowercased
        let file = element.lowercased()
        if extensions.contains(where:  { file.hasSuffix($0) }) {
          return cli
        }
        files.append(file)
        // only check the top level files
        enumerator?.skipDescendants()
      }
    }


    return defaultEditorCli
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
