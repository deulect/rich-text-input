import React, { useRef, useState } from 'react';
import {
  SafeAreaView,
  ScrollView,
  Text,
  View,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  Alert
} from 'react-native';
import {
  RichTextInputView,
  RichTextInputRef,
  RichTextValue,
  RichTextStyle,
  SelectionData,
  createRichTextValue,
  createRichTextStyle
} from '@deulect/rich-text-input';

export default function App() {
  // Refs and state
  const richTextRef = useRef<RichTextInputRef>(null);
  const [currentValue, setCurrentValue] = useState<RichTextValue>(
    createRichTextValue('Welcome to Rich Text Input!\n\nTry selecting text and using the formatting buttons below.')
  );
  const [selection, setSelection] = useState<SelectionData>({
    start: 0,
    end: 0,
    activeStyles: {}
  });

  // Event handlers
  const handleChange = (event: { nativeEvent: { value: RichTextValue } }) => {
    setCurrentValue(event.nativeEvent.value);
  };

  const handleSelectionChange = (event: { 
    nativeEvent: { 
      start: number; 
      end: number; 
      activeStyles: RichTextStyle 
    } 
  }) => {
    const { start, end, activeStyles } = event.nativeEvent;
    setSelection({ start, end, activeStyles });
  };

  // Toolbar actions
  const toggleBold = async () => {
    try {
      await richTextRef.current?.applyStyle(createRichTextStyle(
        !selection.activeStyles.bold,
        selection.activeStyles.italic,
        selection.activeStyles.underline,
        selection.activeStyles.strikethrough
      ));
    } catch (error) {
      console.error('Failed to toggle bold:', error);
    }
  };

  const toggleItalic = async () => {
    try {
      await richTextRef.current?.applyStyle(createRichTextStyle(
        selection.activeStyles.bold,
        !selection.activeStyles.italic,
        selection.activeStyles.underline,
        selection.activeStyles.strikethrough
      ));
    } catch (error) {
      console.error('Failed to toggle italic:', error);
    }
  };

  const toggleUnderline = async () => {
    try {
      await richTextRef.current?.applyStyle(createRichTextStyle(
        selection.activeStyles.bold,
        selection.activeStyles.italic,
        !selection.activeStyles.underline,
        selection.activeStyles.strikethrough
      ));
    } catch (error) {
      console.error('Failed to toggle underline:', error);
    }
  };

  const toggleStrikethrough = async () => {
    try {
      await richTextRef.current?.applyStyle(createRichTextStyle(
        selection.activeStyles.bold,
        selection.activeStyles.italic,
        selection.activeStyles.underline,
        !selection.activeStyles.strikethrough
      ));
    } catch (error) {
      console.error('Failed to toggle strikethrough:', error);
    }
  };

  // Imperative method examples
  const handleClear = async () => {
    try {
      await richTextRef.current?.clear();
    } catch (error) {
      console.error('Failed to clear:', error);
    }
  };

  const handleInsertText = async () => {
    try {
      await richTextRef.current?.insertText(' [Inserted Text] ');
    } catch (error) {
      console.error('Failed to insert text:', error);
    }
  };

  const handleGetValue = async () => {
    try {
      const value = await richTextRef.current?.getValue();
      Alert.alert('Current Value', `Text: "${value?.text}"\nSpans: ${value?.spans.length}`);
    } catch (error) {
      console.error('Error getting value:', error);
    }
  };

  const handleSetSampleText = async () => {
    try {
      const sampleValue = createRichTextValue(
        'This is sample rich text with formatting!',
        [
          { start: 0, end: 4, attributes: { bold: true } },
          { start: 8, end: 14, attributes: { italic: true } },
          { start: 15, end: 24, attributes: { underline: true } },
          { start: 30, end: 40, attributes: { strikethrough: true } }
        ]
      );
      await richTextRef.current?.setValue(sampleValue);
    } catch (error) {
      console.error('Failed to set sample text:', error);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView 
        style={styles.container} 
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView style={styles.scrollView} contentContainerStyle={styles.scrollContent}>
          
          {/* Header */}
          <Text style={styles.header}>Rich Text Input Demo</Text>
          
          {/* Rich Text Input */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Rich Text Editor</Text>
            <View style={styles.editorContainer}>
              <RichTextInputView
                ref={richTextRef}
                initialValue={currentValue}
                onChange={handleChange}
                onSelectionChange={handleSelectionChange}
                placeholder="Start typing your rich text here..."
                multiline={true}
                style={styles.richTextInput}
                autoCapitalize="sentences"
                autoCorrect={true}
                spellCheck={true}
              />
            </View>
          </View>

          {/* Formatting Toolbar */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Formatting Toolbar</Text>
            <View style={styles.toolbar}>
              <ToolbarButton
                title="Bold"
                active={selection.activeStyles.bold || false}
                onPress={toggleBold}
              />
              <ToolbarButton
                title="Italic"
                active={selection.activeStyles.italic || false}
                onPress={toggleItalic}
              />
              <ToolbarButton
                title="Underline"
                active={selection.activeStyles.underline || false}
                onPress={toggleUnderline}
              />
              <ToolbarButton
                title="Strike"
                active={selection.activeStyles.strikethrough || false}
                onPress={toggleStrikethrough}
              />
            </View>
          </View>

          {/* Action Buttons */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Actions</Text>
            <View style={styles.actionButtons}>
              <ActionButton title="Clear" onPress={handleClear} />
              <ActionButton title="Insert Text" onPress={handleInsertText} />
              <ActionButton title="Get Value" onPress={handleGetValue} />
              <ActionButton title="Set Sample" onPress={handleSetSampleText} />
            </View>
          </View>

          {/* Status Display */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Status</Text>
            <View style={styles.statusContainer}>
              <StatusItem 
                label="Text Length" 
                value={currentValue.text.length.toString()} 
              />
              <StatusItem 
                label="Selection" 
                value={`${selection.start}-${selection.end}`} 
              />
              <StatusItem 
                label="Spans" 
                value={currentValue.spans.length.toString()} 
              />
              <StatusItem 
                label="Active Styles" 
                value={Object.keys(selection.activeStyles).filter(
                  key => selection.activeStyles[key as keyof RichTextStyle]
                ).join(', ') || 'None'} 
              />
            </View>
          </View>

          {/* Current Content Preview */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Content Preview</Text>
            <View style={styles.contentPreview}>
              <Text style={styles.contentText} numberOfLines={3}>
                {currentValue.text || 'No content'}
              </Text>
              {currentValue.spans.length > 0 && (
                <Text style={styles.spansText}>
                  Formatting spans: {currentValue.spans.length}
                </Text>
              )}
            </View>
          </View>

        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

// Helper Components

interface ToolbarButtonProps {
  title: string;
  active: boolean;
  onPress: () => void;
}

function ToolbarButton({ title, active, onPress }: ToolbarButtonProps) {
  return (
    <TouchableOpacity
      style={[styles.toolbarButton, active && styles.toolbarButtonActive]}
      onPress={onPress}
    >
      <Text style={[styles.toolbarButtonText, active && styles.toolbarButtonTextActive]}>
        {title}
      </Text>
    </TouchableOpacity>
  );
}

interface ActionButtonProps {
  title: string;
  onPress: () => void;
}

function ActionButton({ title, onPress }: ActionButtonProps) {
  return (
    <TouchableOpacity style={styles.actionButton} onPress={onPress}>
      <Text style={styles.actionButtonText}>{title}</Text>
    </TouchableOpacity>
  );
}

interface StatusItemProps {
  label: string;
  value: string;
}

function StatusItem({ label, value }: StatusItemProps) {
  return (
    <View style={styles.statusItem}>
      <Text style={styles.statusLabel}>{label}:</Text>
      <Text style={styles.statusValue}>{value}</Text>
    </View>
  );
}

// Styles

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 20,
  },
  header: {
    fontSize: 28,
    fontWeight: 'bold',
    textAlign: 'center',
    marginVertical: 20,
    color: '#333',
  },
  section: {
    margin: 16,
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 12,
    color: '#333',
  },
  editorContainer: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    backgroundColor: '#fff',
  },
  richTextInput: {
    minHeight: 120,
    padding: 12,
    fontSize: 16,
    lineHeight: 24,
  },
  toolbar: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  toolbarButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 6,
    backgroundColor: '#f0f0f0',
    borderWidth: 1,
    borderColor: '#ddd',
  },
  toolbarButtonActive: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  toolbarButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333',
  },
  toolbarButtonTextActive: {
    color: '#fff',
  },
  actionButtons: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  actionButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 6,
    backgroundColor: '#34C759',
  },
  actionButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#fff',
  },
  statusContainer: {
    gap: 8,
  },
  statusItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  statusLabel: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  statusValue: {
    fontSize: 14,
    color: '#333',
    fontWeight: '400',
  },
  contentPreview: {
    backgroundColor: '#f8f8f8',
    borderRadius: 6,
    padding: 12,
  },
  contentText: {
    fontSize: 14,
    color: '#333',
    marginBottom: 4,
  },
  spansText: {
    fontSize: 12,
    color: '#666',
    fontStyle: 'italic',
  },
});
