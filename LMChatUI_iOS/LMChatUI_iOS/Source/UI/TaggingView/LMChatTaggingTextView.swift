//
//  LMTaggingTextView.swift
//  lm-feedUI-iOS
//
//  Created by Devansh Mohata on 09/01/24.
//

import UIKit

public protocol LMChatTaggingTextViewProtocol: AnyObject {
    func mentionStarted(with text: String, chatroomId: String)
    func mentionStopped()
    func contentHeightChanged()
    func textViewDidChange(_ textView: UITextView)
    func textViewOnCharacterChange(_ textView: UITextView)
}

extension LMChatTaggingTextViewProtocol {
    public func textViewDidChange(_ textView: UITextView) {}
    public func textViewOnCharacterChange(_ textView: UITextView) {}
}

public extension LMChatTaggingTextViewProtocol {
    func contentHeightChanged() { }
}

@IBDesignable
open class LMChatTaggingTextView: LMTextView {
    public var rawText: String = ""
    public var isMentioning: Bool = false {
        willSet {
            if !newValue {
                mentionDelegate?.mentionStopped()
            }
        }
    }
    public var spaceChar: Character = " "
    public var newLineChar: Character = "\n"
    public var isSpaceAdded: Bool = false
    public var startIndex: Int?
    public var characters: [Character] = []
    public var chatroomId: String = ""
    
    public weak var mentionDelegate: LMChatTaggingTextViewProtocol?
    
    public var textAttributes: [NSAttributedString.Key: Any] { [.font: self.font ?? Appearance.shared.fonts.textFont1,
                                                                .foregroundColor: typingTextColor]
    }
    
    public var placeholderColor: UIColor = Appearance.shared.colors.previewSubtitleTextColor
    public var typingTextColor: UIColor = Appearance.shared.colors.black
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        delegate = self
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }
    
    public func handleTagging() {
        let selectedLocation = selectedRange.location
        
        var encounteredRoute = false
        var taggingText = ""
        
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: selectedLocation), options: .reverse) {attr, range, _ in
            if attr.contains(where: { $0.key == .route }) {
                encounteredRoute = true
            } else if !encounteredRoute {
                taggingText.append(attributedText.attributedSubstring(from: range).string)
            }
        }
        
        isMentioning = false
        taggingText = taggingText.trimmingCharacters(in: .whitespacesAndNewlines)
        isSpaceAdded = false
        characters.removeAll()
        startIndex = nil
        
        for (idx, char) in Array(taggingText).reversed().enumerated() {
            if char == "@" {
                startIndex = selectedLocation - idx - 1
                isMentioning = true
                break
            } else if char == spaceChar {
                if isSpaceAdded {
                    isMentioning = false
                    break
                } else {
                    isSpaceAdded = true
                }
            } else if char == newLineChar {
                isMentioning = false
                break
            }
            characters.append(char)
        }
        
        characters = characters.reversed()
        
        guard isMentioning else { return }
        
        mentionDelegate?.mentionStarted(with: String(characters), chatroomId: chatroomId)
    }
    
    public func addTaggedUser(with username: String, route: String) {
        if let startIndex {
            let partOneString = NSMutableAttributedString(attributedString: attributedText.attributedSubstring(from: NSRange(location: 0, length: startIndex)))
            let partTwoString = NSMutableAttributedString(attributedString: attributedText.attributedSubstring(from: NSRange(location: startIndex + 1 + characters.count, length: attributedText.length - startIndex - 1 - characters.count)))
            
            let attrName = NSAttributedString(string: "\(username.trimmingCharacters(in: .whitespacesAndNewlines))", attributes: [
                .font: (textAttributes[.font] as? UIFont) ?? Appearance.shared.fonts.textFont1,
                .foregroundColor: Appearance.shared.colors.linkColor,
                .route: route
            ])
            
            var newLocation = 1
            newLocation += partOneString.length
            newLocation += attrName.length
            
            partTwoString.insert(.init(string: " "), at: 0)
            
            let attrString =  NSMutableAttributedString(attributedString: partOneString)
            attrString.append(attrName)
            attrString.append(partTwoString)
            
            let tempAttrString = attrString
            
            tempAttrString.enumerateAttributes(in: NSRange(location: 0, length: tempAttrString.length)) { attr, range, _ in
                if attr.contains(where: { $0.key == .route }) {
                    attrString.addAttributes(linkTextAttributes, range: range)
                } else {
                    attrString.addAttributes(textAttributes, range: range)
                }
            }
            
            attributedText = attrString
            selectedRange = NSRange(location: newLocation, length: 0)
            characters.removeAll(keepingCapacity: true)
            mentionDelegate?.contentHeightChanged()
        }
    }
    
    public func getText() -> String {
        var message = ""
        
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length)) { attr, range, _ in
            if let route = attr.first(where: { $0.key == .route })?.value as? String {
                message.append(route)
            } else {
                message.append(attributedText.attributedSubstring(from: range).string)
            }
        }
        message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return message != placeHolderText ? message : ""
    }
    
    public func setAttributedText(from content: String, prefix: String? = nil) {
        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            attributedText = GetAttributedTextWithRoutes.getAttributedText(from: content)
        } else {
            text = placeHolderText
            textColor = placeholderColor
            font = textAttributes[.font] as? UIFont
        }
        mentionDelegate?.contentHeightChanged()
    }
}


// MARK: UITextViewDelegate
extension LMChatTaggingTextView: UITextViewDelegate {
    
    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        #if DEBUG
            mentionDelegate?.contentHeightChanged()
            return true
        #endif
       if text.isEmpty {
            if isMentioning {
                if range.length <= characters.count {
                    characters.removeLast(range.length)
                } else {
                    startIndex = nil
                    isMentioning.toggle()
                    characters.removeAll(keepingCapacity: true)
                }
            }
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            var newRange = range
            
            textView.attributedText.enumerateAttributes(in: .init(location: 0, length: textView.attributedText.length)) { attributes, xRange, _ in
                if attributes.contains(where: { $0.key == .route }),
                   NSIntersectionRange(xRange, range).length > 0 {
                    newRange = NSUnionRange(newRange, xRange)
                }
            }
            
            attrString.deleteCharacters(in: newRange)
            textView.attributedText = attrString
            
            var oldSelectedRange = textView.endOfDocument
            
            if let newPos = textView.position(from: textView.beginningOfDocument, offset: newRange.lowerBound) {
                oldSelectedRange = newPos
            }
            
            textView.selectedTextRange = textView.textRange(from: oldSelectedRange, to: oldSelectedRange)
            
            mentionDelegate?.contentHeightChanged()
            return false
        }

        mentionDelegate?.contentHeightChanged()
        return true
    }
    
    open func textViewDidChangeSelection(_ textView: UITextView) {
        var position = textView.selectedRange
        if position.length > .zero {
            textView.attributedText.enumerateAttributes(in: .init(location: 0, length: textView.attributedText.length)) { attr, range, _ in
                if attr.contains(where: { $0.key == .route }),
                   NSIntersectionRange(range, textView.selectedRange).length > 0 {
                    position = NSUnionRange(range, position)
                }
            }
            
            textView.selectedRange = position
        } else if let range = textView.attributedText.attributeRange(at: position.location, for: .route) {
            let distanceToStart = abs(range.location - position.location)
            let distanceToEnd = abs(range.location + range.length - position.location)
            
            if distanceToStart < distanceToEnd {
                textView.selectedRange = .init(location: range.location, length: 0)
            } else {
                textView.selectedRange = .init(location: range.location + range.length, length: 0)
            }
        }
        
        let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
        
        textView.attributedText.enumerateAttributes(in: NSRange(location: 0, length: textView.attributedText.length)) { attr, range, _ in
            if attr.contains(where: { $0.key == .route }) {
                attrString.addAttributes(linkTextAttributes, range: range)
            } else {
                attrString.addAttributes(textAttributes, range: range)
            }
        }
        
        textView.attributedText = attrString
        
        if textView.text != placeHolderText {
            handleTagging()
        }
        // Added this conditon to fix the placeholder color, if text is placeholder text.
        if textView.text == placeHolderText {
            textView.text = placeHolderText
            textView.textColor = placeholderColor
        }
    }
    
    open func textViewDidChange(_ textView: UITextView) {
        mentionDelegate?.textViewDidChange(textView)
        mentionDelegate?.contentHeightChanged()
    }
    
    open func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeHolderText {
            textView.text = nil
            textView.textColor = typingTextColor
        }
    }
    
    open func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeHolderText
            textView.textColor = placeholderColor
        }
        mentionDelegate?.contentHeightChanged()
    }
}
