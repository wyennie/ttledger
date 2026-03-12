// @tiptap/extension-table-row@2.11.0 downloaded from https://ga.jspm.io/npm:@tiptap/extension-table-row@2.11.0/dist/index.js

import{Node as t,mergeAttributes as e}from"@tiptap/core";const r=t.create({name:"tableRow",addOptions(){return{HTMLAttributes:{}}},content:"(tableCell | tableHeader)*",tableRole:"row",parseHTML(){return[{tag:"tr"}]},renderHTML({HTMLAttributes:t}){return["tr",e(this.options.HTMLAttributes,t),0]}});export{r as TableRow,r as default};

