import Testing
import CoreGraphics
@testable import SwiftVerificarWCAGAlgs

// MARK: - Test Double

/// A minimal concrete type conforming to ContentChunk for testing purposes.
struct MockContentChunk: ContentChunk {
    let boundingBox: BoundingBox
}

@Suite("ContentChunk Protocol Tests")
struct ContentChunkTests {

    // MARK: - Protocol Conformance Tests

    @Test("Concrete chunk has correct bounding box")
    func boundingBox() {
        let box = BoundingBox(pageIndex: 3, x: 10, y: 20, width: 100, height: 50)
        let chunk = MockContentChunk(boundingBox: box)
        #expect(chunk.boundingBox == box)
    }

    @Test("pageIndex defaults to bounding box pageIndex")
    func pageIndexDefault() {
        let box = BoundingBox(pageIndex: 5, x: 10, y: 20, width: 100, height: 50)
        let chunk = MockContentChunk(boundingBox: box)
        #expect(chunk.pageIndex == 5)
    }

    @Test("pageIndex returns 0 for first page")
    func pageIndexZero() {
        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        let chunk = MockContentChunk(boundingBox: box)
        #expect(chunk.pageIndex == 0)
    }

    @Test("Chunk is Sendable")
    func sendableConformance() {
        let box = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        let chunk = MockContentChunk(boundingBox: box)
        // If this compiles, the type is Sendable
        let _: any Sendable = chunk
        #expect(chunk.pageIndex == 0)
    }

    @Test("ContentChunk protocol can be used as existential")
    func existentialUsage() {
        let box1 = BoundingBox(pageIndex: 0, x: 0, y: 0, width: 50, height: 50)
        let box2 = BoundingBox(pageIndex: 1, x: 10, y: 10, width: 30, height: 30)
        let chunks: [any ContentChunk] = [
            MockContentChunk(boundingBox: box1),
            MockContentChunk(boundingBox: box2)
        ]
        #expect(chunks.count == 2)
        #expect(chunks[0].pageIndex == 0)
        #expect(chunks[1].pageIndex == 1)
    }

    @Test("Multiple chunks can be filtered by page")
    func filterByPage() {
        let chunks: [any ContentChunk] = [
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)),
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10)),
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 0, x: 50, y: 50, width: 10, height: 10)),
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 2, x: 0, y: 0, width: 10, height: 10))
        ]
        let page0Chunks = chunks.filter { $0.pageIndex == 0 }
        #expect(page0Chunks.count == 2)
    }

    @Test("Chunk bounding box properties are accessible through protocol")
    func boundingBoxPropertiesThroughProtocol() {
        let chunk: any ContentChunk = MockContentChunk(
            boundingBox: BoundingBox(pageIndex: 0, x: 10, y: 20, width: 100, height: 50)
        )
        #expect(chunk.boundingBox.leftX == 10)
        #expect(chunk.boundingBox.bottomY == 20)
        #expect(chunk.boundingBox.rightX == 110)
        #expect(chunk.boundingBox.topY == 70)
        #expect(chunk.boundingBox.width == 100)
        #expect(chunk.boundingBox.height == 50)
        #expect(chunk.boundingBox.area == 5000)
    }

    @Test("Chunks can be sorted by page index")
    func sortByPage() {
        var chunks: [MockContentChunk] = [
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 3, x: 0, y: 0, width: 10, height: 10)),
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)),
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 1, x: 0, y: 0, width: 10, height: 10))
        ]
        chunks.sort { $0.pageIndex < $1.pageIndex }
        #expect(chunks[0].pageIndex == 0)
        #expect(chunks[1].pageIndex == 1)
        #expect(chunks[2].pageIndex == 3)
    }

    @Test("Chunk bounding boxes can be collected into MultiBoundingBox")
    func collectBoundingBoxes() {
        let chunks: [MockContentChunk] = [
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 0, x: 0, y: 0, width: 10, height: 10)),
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 1, x: 0, y: 0, width: 20, height: 20)),
            MockContentChunk(boundingBox: BoundingBox(pageIndex: 0, x: 50, y: 50, width: 10, height: 10))
        ]
        let multi = MultiBoundingBox(boxes: chunks.map(\.boundingBox))
        #expect(multi.count == 3)
        #expect(multi.pageCount == 2)
        #expect(multi.isMultiPage)
    }
}
