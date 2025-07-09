import * as React from 'react';

import { RichTextInputViewProps } from './RichTextInput.types';

export default function RichTextInputView(props: RichTextInputViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
