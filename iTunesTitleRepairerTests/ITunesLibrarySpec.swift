import Quick
import Nimble

class ITunesLibrarySpec: QuickSpec {
    override func spec() {
        var lib: ITunesLibrary =  ITunesLibrary()
        var loadeErr: NSError!
        beforeEach {
            loadeErr = lib.load("./iTunesTitleRepairerTests/iTunesLibrary.xml")
        }
        describe("#load") {
            it("iTunesLibary XMLファイルを読み込める") {
                expect(loadeErr).to(beNil())
                expect(lib.libaryDict.count).to(equal(9))
                expect(((lib.libaryDict["Tracks"] as NSDictionary).allKeys as [String]).count).to(equal(4))
            }
            it("iTunesLibary XMLファイルが存在しない場合はErrorを戻す") {
                let err = lib.load("./iTunesTitleRepairerTests/NOiTunesLibrary.xml")
                expect(err!.localizedDescription).to(contain("no such file"))
            }
        }
        describe("#save") {
            let NewLibFolder = "/tmp"
            let NewLibPath = NewLibFolder.stringByAppendingPathComponent(ITunesLibrary.LibraryXmlFileName)
            let MpegTitlesPath = NewLibFolder.stringByAppendingPathComponent(ITunesLibrary.MpegTitleFileName)
            
            let fileMan = NSFileManager.defaultManager()
            beforeEach {
               var _ = fileMan.removeItemAtPath(NewLibPath, error: nil)
            }
            it("ファイルに保存出来る") {
                expect(lib.save(NewLibFolder)).to(beNil())
                expect(fileMan.fileExistsAtPath(NewLibPath)).to(beTruthy())
                expect(fileMan.fileExistsAtPath(MpegTitlesPath)).to(beTruthy())
            }
            it("変更内容が書き込まれている") {
                var _ = lib.replaceTiles([6257, 6259], ["名もない恋愛", "足ながおじさんになれずに"])
                var _ = lib.save(NewLibFolder)
                
                var newLib: ITunesLibrary =  ITunesLibrary()
                newLib.load(NewLibPath)
                expect(newLib.songTitle(6257)).to(equal("名もない恋愛"))
            }
            it("音楽ファイル名変更用shell scriptも書かれる") {
                var _ = lib.replaceTiles([6257, 6259], ["VOLARE (NEL BLU DIPINTO DI BLU) / ボラーレ", "SARAVAH! / サラヴァ!"])
                var _ = lib.save(NewLibFolder)
                
                expect(NSString(contentsOfFile: MpegTitlesPath, encoding: NSUTF8StringEncoding, error: nil)).to(equal(
                    "/Users/yy/Music/iTunes/iTunes Media/Music/高橋幸宏/Saravah!/01 AudioTrack 01.mp3\tVOLARE (NEL BLU DIPINTO DI BLU) / ボラーレ\n/Users/yy/Music/iTunes/iTunes Media/Music/高橋幸宏/Saravah!/02 AudioTrack 02.mp3\tSARAVAH! / サラヴァ!\n"))
            }
        }
        describe("#searchAlubm") {
            it("アルバム名で検索し曲名のTrackIDを戻す") {
                expect(lib.searchAlubm("A Day in the next life")).to(equal([5791, 5793]))
            }
        }
        describe("#songTitle") {
            it("指定されたTrackIDの曲名を戻す") {
                expect(lib.songTitle(5791)).to(equal("震える惑星（ほし）"))
            }
        }
        describe(".parse") {
            it("Amazonの曲名リストから曲名の配列を取得する") {
                let chunk = "1. VOLARE (NEL BLU DIPINTO DI BLU) / ボラーレ\t試聴する\n" +
                    "2. SARAVAH! / サラヴァ!\t試聴する\n" +
                    "1. 名もない恋愛\n" +
                    "2. 足ながおじさんになれずに\n" +
                    "%E8%A9%A6%E8%81%B4%E3%81%99%E3%82%8B\t  1. 二人の迷路\t 5:31\t￥ 257\t  楽曲を購入 \n" +
                    "%E8%A9%A6%E8%81%B4%E3%81%99%E3%82%8B\t  2. Negative\t 4:38\t￥ 257\t  楽曲を購入 \n"

                expect(ITunesLibrary.parse(chunk)).to(equal(
                    ["VOLARE (NEL BLU DIPINTO DI BLU) / ボラーレ", "SARAVAH! / サラヴァ!", "名もない恋愛", "足ながおじさんになれずに",
                     "二人の迷路", "Negative"]))
            }
        }
        describe("#replaceTiles") {
            it("指定された複数のidの曲名を置き換える") {
                let err = lib.replaceTiles([6257, 6259], ["VOLARE (NEL BLU DIPINTO DI BLU) / ボラーレ", "SARAVAH! / サラヴァ!"])

                expect(err).to(beNil())
                expect(lib.songTitle(6257)).to(equal("VOLARE (NEL BLU DIPINTO DI BLU) / ボラーレ"))
                expect(lib.songTitle(6259)).to(equal("SARAVAH! / サラヴァ!"))
                println(lib.mpegTitleList[0].description)
            }
        }
    }
}
