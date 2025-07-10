// src/types/jsoneditor-react.d.ts

declare module 'jsoneditor-react' {
  import * as React from 'react';
  import { JSONEditorMode, JSONEditorOptions } from 'jsoneditor'; // Import types from the core jsoneditor library

  interface JsonEditorProps {
    value?: object | null;
    mode?: JSONEditorMode;
    modes?: JSONEditorMode[];
    onChange?: (json: object) => void;
    onModeChange?: (mode: JSONEditorMode) => void;
    onError?: (error: Error) => void;
    // You can add more props that jsoneditor-react supports here as needed
    // For example, if it passes through all JSONEditorOptions:
    htmlElementProps?: React.HTMLAttributes<HTMLDivElement>;
    className?: string; // If it supports className directly
    // Any other props that the library's documentation indicates
    tag?: string; // if it allows changing the root element tag
    // If it passes jsoneditor options directly, you can extend JSONEditorOptions
    // E.g., options?: JSONEditorOptions;
  }

  // This declares a React component that takes JsonEditorProps
  export class JsonEditor extends React.Component<JsonEditorProps, any> {}

  // If it's a default export (which it often is for `jsoneditor-react`):
  export default JsonEditor;
}