// @tiptap/extension-paragraph@2.11.0 downloaded from https://ga.jspm.io/npm:@tiptap/extension-paragraph@2.11.0/dist/index.js

import{Node as t,mergeAttributes as r}from"@tiptap/core";const e=t.create({name:"paragraph",priority:1e3,addOptions(){return{HTMLAttributes:{}}},group:"block",content:"inline*",parseHTML(){return[{tag:"p"}]},renderHTML({HTMLAttributes:t}){return["p",r(this.options.HTMLAttributes,t),0]},addCommands(){return{setParagraph:()=>({commands:t})=>t.setNode(this.name)}},addKeyboardShortcuts(){return{"Mod-Alt-0":()=>this.editor.commands.setParagraph()}}});export{e as Paragraph,e as default};

