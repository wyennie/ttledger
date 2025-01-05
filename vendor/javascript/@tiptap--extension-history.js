// @tiptap/extension-history@2.11.0 downloaded from https://ga.jspm.io/npm:@tiptap/extension-history@2.11.0/dist/index.js

import{Extension as o}from"@tiptap/core";import{undo as t,redo as d,history as r}from"@tiptap/pm/history";const e=o.create({name:"history",addOptions(){return{depth:100,newGroupDelay:500}},addCommands(){return{undo:()=>({state:o,dispatch:d})=>t(o,d),redo:()=>({state:o,dispatch:t})=>d(o,t)}},addProseMirrorPlugins(){return[r(this.options)]},addKeyboardShortcuts(){return{"Mod-z":()=>this.editor.commands.undo(),"Shift-Mod-z":()=>this.editor.commands.redo(),"Mod-y":()=>this.editor.commands.redo(),"Mod-я":()=>this.editor.commands.undo(),"Shift-Mod-я":()=>this.editor.commands.redo()}}});export{e as History,e as default};

