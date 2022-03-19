#!/usr/bin/env swift

import Foundation

class SourceTree {
	init() {	}

	func run () {
		guard let data = try? Data(contentsOf: plistPath) else {
			let alfredResult = AlfredResult(items: [
				AlfredItem(title: "SourceTree not installed", subtitle: "Press enter to open SourceTree homepage and download it", arg: "open \"https://sourcetreeapp.com/\"")
			])
			prettyPrint(alfredResult)
			return
		}
		do {
			let parsed = try PropertyListDecoder().decode(SourceTreePlist.self, from: data)
			let alfredResult = toAlfredResult(parsed.objects)
			prettyPrint(alfredResult)
		} catch {
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
			let alfredResult = AlfredResult(items: [
				AlfredItem(
					title: "Error occurred",
					subtitle: "Press enter to open github and report an issue to me",
					arg: "open \"\(urlComponents.url?.absoluteString ?? githubNewIssueUrl)\""
				)	
			])
			prettyPrint(alfredResult)
		}
	}
	
	func prettyPrint<T: Encodable>(_ v: T) {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		guard let data = try? encoder.encode(v) else { return }
		print(String(data: data, encoding: .utf8)!)
	}
	
	func toAlfredResult(_ objects: [String]) -> AlfredResult {
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

		var items: [AlfredItem] = namePathGroups.map { (name, path) in
			let mod = AlfredItemModItem(valid: true, arg: "open \"\(path)\"", subtitle: "Reveal in Finder")
			return AlfredItem(title: name, subtitle: path, match: spaceWords(name), arg: path, mods: AlfredItemMod(cmd: mod))
		}
		
		if items.isEmpty {
			items.append(AlfredItem(title: "Your SourceTree Bookmark Is Empty ", subtitle: "Please add repos to SourceTree first"))
		}

		return AlfredResult(items: items)
	}

	func spaceWords(_ string: String) -> String {
		string
			.replacingOccurrences(of: #"[\/\\_-]"#, with: " ", options: .regularExpression, range: nil)
			.replacingOccurrences(of: #"([A-Z])"#, with: " $1", options: .regularExpression, range: nil)
	}
	
	func readFile(path: URL) {
		FileManager.default.contents(atPath: path.path)
	}
	/** SourceTree browser.plist path  */
	var plistPath: URL {
		let url = FileManager.default.homeDirectoryForCurrentUser
		return url.appendingPathComponent("Library/Application Support/SourceTree/browser.plist")
	}
	
	struct AlfredResult: Codable {
		let items: [AlfredItem]
	}

	struct AlfredItem: Codable {
		var title: String
		var subtitle: String
		var match: String?
		var arg: String?
		var mods: AlfredItemMod?
	}
	
	struct AlfredItemMod: Codable {
		var cmd: AlfredItemModItem
	}
	
	struct AlfredItemModItem: Codable {
		var valid: Bool
		var arg: String
		var subtitle: String
	}
	
	struct SourceTreePlist: Codable {
		let version: Int
		let objects: [String]
		
		enum CodingKeys: String, CodingKey {
			case version = "$version"
			case objects = "$objects"
		}
	}
}

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
