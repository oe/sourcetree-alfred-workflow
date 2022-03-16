#!/usr/bin/env swift

import Foundation

class SourceTree {
	init() {	}
	
	func parsePlist () {
		guard let data = try? Data(contentsOf: plistPath) else {
			return
		}
		do {
			let parsed = try PropertyListDecoder().decode(SourceTreePlist.self, from: data)
			let alfredResult = toAlfredResult(parsed.objects)
			prettyPrint(alfredResult)
		} catch {
			print("failed to parse: ")
			print(error)
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
		
		let items = namePathGroups.map { (name, path) in
			AlfredItem(title: name, subtitle: path, arg: path, match: spaceWords(name))
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
		var arg: String
		var match: String
	}
	
	struct SourceTreePlist: Codable {
		let version: Int
		let objects: [String]
		
		enum CodingKeys: String, CodingKey {
			case version = "$version"
			case objects = "$objects"
		}
	}
	
	struct ObjectItem: Codable {
		let string: String?
	}	
}

extension SourceTree.SourceTreePlist {
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		version = try container.decode(Int.self, forKey: .version)
		let objectItems = try container.decode([SourceTree.ObjectItem].self, forKey: .objects) 
		objects = objectItems.map { $0.string } .compactMap { $0 }
	}
}

extension SourceTree.ObjectItem {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		string = try? container.decode(String.self)
	}
}


SourceTree().parsePlist()
