// @tiptap/extension-task-list@2.11.0 downloaded from https://ga.jspm.io/npm:@tiptap/extension-task-list@2.11.0/dist/index.js

import{Node as t,mergeAttributes as e}from"@tiptap/core";const s=t.create({name:"taskList",addOptions(){return{itemTypeName:"taskItem",HTMLAttributes:{}}},group:"block list",content(){return`${this.options.itemTypeName}+`},parseHTML(){return[{tag:`ul[data-type="${this.name}"]`,priority:51}]},renderHTML({HTMLAttributes:t}){return["ul",e(this.options.HTMLAttributes,t,{"data-type":this.name}),0]},addCommands(){return{toggleTaskList:()=>({commands:t})=>t.toggleList(this.name,this.options.itemTypeName)}},addKeyboardShortcuts(){return{"Mod-Shift-9":()=>this.editor.commands.toggleTaskList()}}});export{s as TaskList,s as default};

