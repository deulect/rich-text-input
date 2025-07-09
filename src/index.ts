// Reexport the native module. On web, it will be resolved to RichTextInputModule.web.ts
// and on native platforms to RichTextInputModule.ts
export { default } from './RichTextInputModule';
export { default as RichTextInputView } from './RichTextInputView';
export * from  './RichTextInput.types';
