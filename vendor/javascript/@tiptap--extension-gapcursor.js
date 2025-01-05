// @tiptap/extension-gapcursor@2.11.0 downloaded from https://ga.jspm.io/npm:@tiptap/extension-gapcursor@2.11.0/dist/index.js

import{Extension as r,callOrReturn as o,getExtensionField as a}from"@tiptap/core";import{gapCursor as t}from"@tiptap/pm/gapcursor";const e=r.create({name:"gapCursor",addProseMirrorPlugins(){return[t()]},extendNodeSchema(r){var t;const e={name:r.name,options:r.options,storage:r.storage};return{allowGapCursor:(t=o(a(r,"allowGapCursor",e)))!==null&&t!==void 0?t:null}}});export{e as Gapcursor,e as default};

