import { registerWebModule, NativeModule } from 'expo';

import { RichTextInputModuleEvents } from './RichTextInput.types';

class RichTextInputModule extends NativeModule<RichTextInputModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(RichTextInputModule, 'RichTextInputModule');
