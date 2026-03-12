// @tiptap/extension-table-cell@2.11.0 downloaded from https://ga.jspm.io/npm:@tiptap/extension-table-cell@2.11.0/dist/index.js

import{Node as t,mergeAttributes as e}from"@tiptap/core";const r=t.create({name:"tableCell",addOptions(){return{HTMLAttributes:{}}},content:"block+",addAttributes(){return{colspan:{default:1},rowspan:{default:1},colwidth:{default:null,parseHTML:t=>{const e=t.getAttribute("colwidth");const r=e?e.split(",").map((t=>parseInt(t,10))):null;return r}}}},tableRole:"cell",isolating:true,parseHTML(){return[{tag:"td"}]},renderHTML({HTMLAttributes:t}){return["td",e(this.options.HTMLAttributes,t),0]}});export{r as TableCell,r as default};

