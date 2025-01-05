// @tiptap/extension-list-item@2.11.0 downloaded from https://ga.jspm.io/npm:@tiptap/extension-list-item@2.11.0/dist/index.js

import{Node as t,mergeAttributes as e}from"@tiptap/core";const i=t.create({name:"listItem",addOptions(){return{HTMLAttributes:{},bulletListTypeName:"bulletList",orderedListTypeName:"orderedList"}},content:"paragraph block*",defining:true,parseHTML(){return[{tag:"li"}]},renderHTML({HTMLAttributes:t}){return["li",e(this.options.HTMLAttributes,t),0]},addKeyboardShortcuts(){return{Enter:()=>this.editor.commands.splitListItem(this.name),Tab:()=>this.editor.commands.sinkListItem(this.name),"Shift-Tab":()=>this.editor.commands.liftListItem(this.name)}}});export{i as ListItem,i as default};

