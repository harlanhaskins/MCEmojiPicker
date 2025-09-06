// The MIT License (MIT)
//
// Copyright © 2022 Ivan Izyumkin
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

/// Protocol for the `MCEmojiPickerViewModel`.
protocol MCEmojiPickerViewModelProtocol {
    /// Whether the picker shows empty categories. Default false.
    var showEmptyEmojiCategories: Bool { get set }
    /// The emoji categories being used
    var emojiCategories: [MCEmojiCategory] { get }
    /// The observed variable that is responsible for the choice of emoji.
    var selectedEmoji: Observable<MCEmoji?> { get set }
    /// The search text, if any, to filter the emoji list.
    var searchText: String { get set }
    /// The observed variable that is responsible for the choice of emoji category.
    var selectedEmojiCategoryType: Observable<MCEmojiCategoryType> { get set }
    /// Clears the selected emoji, setting to `nil`.
    func clearSelectedEmoji()
    /// Returns the number of categories with emojis.
    func numberOfSections() -> Int
    /// Returns the number of emojis in the target section.
    func numberOfItems(for type: MCEmojiCategoryType) -> Int
    /// Returns the `MCEmoji` for the target `IndexPath`.
    func emoji(at indexPath: IndexPath) -> MCEmoji
    /// Returns the localized section name for the target section.
    func sectionHeaderName(for type: MCEmojiCategoryType) -> String
    /// Updates the emoji skin tone and returns the updated `MCEmoji`.
    func updateEmojiSkinTone(_ skinToneRawValue: Int, in indexPath: IndexPath) -> MCEmoji
}

/// View model which using in `MCEmojiPickerViewController`.
final class MCEmojiPickerViewModel: MCEmojiPickerViewModelProtocol {
    
    // MARK: - Public Properties
    
    public var selectedEmoji = Observable<MCEmoji?>(value: nil)
    public lazy var selectedEmojiCategoryType = Observable<MCEmojiCategoryType>(value: allEmojiCategories[0].type)
    public var showEmptyEmojiCategories = false
    public private(set) var emojiCategories: [MCEmojiCategory] = []

    public var searchText: String = "" {
        didSet {
            updateEmojiCategories()
        }
    }

    // MARK: - Private Properties
    
    /// All emoji categories.
    private var allEmojiCategories = [MCEmojiCategory]()
    
    // MARK: - Initializers
    
    init(unicodeManager: MCUnicodeManagerProtocol = MCUnicodeManager()) {
        allEmojiCategories = unicodeManager.getEmojisForCurrentIOSVersion()

        // Increment usage of each emoji upon selection
        selectedEmoji.bind { emoji in
            emoji?.incrementUsageCount()
        }

        updateEmojiCategories()
    }

    public func updateEmojiCategories() {
        var displayedEmojiCategories = allEmojiCategories

        if !searchText.isEmpty {
            for i in displayedEmojiCategories.indices {
                displayedEmojiCategories[i].emojis.removeAll {
                    !$0.searchKey.localizedCaseInsensitiveContains(searchText) &&
                        !$0.string.localizedCaseInsensitiveContains(searchText)
                }
            }
        }

        if !showEmptyEmojiCategories {
            displayedEmojiCategories.removeAll { $0.emojis.count == 0 }
        }

        emojiCategories = displayedEmojiCategories
    }

    // MARK: - Public Methods
    
    public func clearSelectedEmoji() {
        selectedEmoji.value = nil
    }
    
    public func numberOfSections() -> Int {
        return emojiCategories.count
    }
    
    public func numberOfItems(for type: MCEmojiCategoryType) -> Int {
        return emojiCategories.first { $0.type == type }?.emojis.count ?? 0
    }
    
    public func emoji(at indexPath: IndexPath) -> MCEmoji {
        return emojiCategories[indexPath.section].emojis[indexPath.row]
    }
    
    public func sectionHeaderName(for type: MCEmojiCategoryType) -> String {
        return emojiCategories.first { $0.type == type }?.categoryName ?? ""
    }
    
    public func updateEmojiSkinTone(_ skinToneRawValue: Int, in indexPath: IndexPath) -> MCEmoji {
        let categoryType: MCEmojiCategoryType = emojiCategories[indexPath.section].type
        let allCategoriesIndex: Int = allEmojiCategories.firstIndex { $0.type == categoryType } ?? 0
        allEmojiCategories[allCategoriesIndex].emojis[indexPath.row].set(skinToneRawValue: skinToneRawValue)
        updateEmojiCategories()
        return allEmojiCategories[allCategoriesIndex].emojis[indexPath.row]
    }
}
