////
//  MobiledocKit
//

import XCTest
@testable import MobiledocKit

class MobileDocTests: XCTestCase {
    lazy var dummyBundle: Bundle = {
        return Bundle(for: self.classForCoder)
    }()
    
    func testCreatingMobileDocFromJSON()  {
        let url =  dummyBundle.url(forResource: "mobiledoccard", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        let card = try? decoder.decode([MobiledocCard].self, from: data)
        XCTAssertNotNil(card)
        
        let notacard =  try? decoder.decode([MobiledocCard].self, from: "[{\"title\":\"sup\"]".data(using: .utf8)!)
        XCTAssertNil(notacard)
    }
    
    func testMobileMarkdownCardDecoding() {
        let url = dummyBundle.url(forResource: "markdowncard", withExtension: "json")!
        let decoder = JSONDecoder()
        do {
            let rawCard = try Data(contentsOf: url)
            let _ = try decoder.decode(MobiledocCard.self, from: rawCard)
        } catch{
            XCTFail(String(describing: error))
        }
    }
    
    func testDecodingSections() {
        let raw = "{\"version\":\"0.3.1\",\"atoms\":[],\"cards\":[],\"markups\":[],\"sections\":[[1,\"p\",[[0,[],0,\"Hmmm\"]]]]}"
        let mobiledoc = try! JSONDecoder().decode(Mobiledoc.self, from: raw.data(using: .utf8)!)
        
        guard let section = mobiledoc.sections[0] as? MarkerSection else {
            XCTFail("Incorrect section parsed")
            return
        }
        
        XCTAssertEqual(section.markers.first?.value, "Hmmm")
    }
    
    func testDecodingProblemPost() {
        let raw = "{\"version\":\"0.3.1\",\"atoms\":[],\"cards\":[[\"markdown\",{\"markdown\":\"Non-markdowned stuff\"}]],\"markups\":[],\"sections\":[[10,0],[1,\"p\",[[0,[],0,\"This is regular text\"]]]]}"
        let mobiledoc = try! JSONDecoder().decode(Mobiledoc.self, from: raw.data(using: .utf8)!)
        XCTAssertEqual(renderMarkdown(mobiledoc), "Non-markdowned stuff\n\nThis is regular text\n")
    }
    
    func testReencoding() throws {
        let mobiledoc = Mobiledoc(
            markups: ["b"],
            cards: [
                MobiledocCard("this is a *thing*")
            ],
            sections: [
                CardSection(cardIndex:0),
                ImageSection(src: "https://cdn.bulbagarden.net/upload/thumb/5/5d/010Caterpie.png/250px-010Caterpie.png"),
                ListSection(tagName: .ol, markers: [Marker(textType: .text, markupIndexes: [0], numberOfClosedMarkups: 1, value: "bold?")]),
                MarkerSection(tagName: .h1, markers: [Marker(textType: .text, markupIndexes: [], numberOfClosedMarkups: 0, value: "header?")])
            ]
        )
        
        let encoded = try JSONEncoder().encode(mobiledoc)
        let decoded = try JSONDecoder().decode(Mobiledoc.self, from: encoded)
        
        XCTAssertEqual(mobiledoc, decoded)
    }
    
    struct GibberishPosts: Decodable {
        let posts: [GibberishPost]
    }
    
    struct GibberishPost: Decodable {
        let mobiledoc: String
    }
    
    func testDecodingGibberish() {
        let url = dummyBundle.url(forResource: "gibberish", withExtension: "json")!
        let raw = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        let posts = try! decoder.decode(GibberishPosts.self, from: raw)
        let post = posts.posts[0]
        
        let doc = try? decoder.decode(Mobiledoc.self, from: post.mobiledoc.data(using: .utf8)!)
        XCTAssertNotNil(doc)
    }
    
    func testNonEquivalentDocs() {
        let doc1 = Mobiledoc(markups: [], cards: [MobiledocCard("sup")], sections: [CardSection(cardIndex: 0)])
        let doc2 = Mobiledoc(markups: [], cards: [MobiledocCard("sup")], sections: [ImageSection(src: "image!")])
        
        XCTAssertNotEqual(doc1, doc2)
    }
}

