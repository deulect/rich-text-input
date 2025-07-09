import { requireNativeView } from 'expo';
import * as React from 'react';

import { RichTextInputViewProps } from './RichTextInput.types';

const NativeView: React.ComponentType<RichTextInputViewProps> =
  requireNativeView('RichTextInput');

export default function RichTextInputView(props: RichTextInputViewProps) {
  return <NativeView {...props} />;
}
