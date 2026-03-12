// @tiptap/extension-table-header@2.11.0 downloaded from https://ga.jspm.io/npm:@tiptap/extension-table-header@2.11.0/dist/index.js

import{Node as t,mergeAttributes as e}from"@tiptap/core";const r=t.create({name:"tableHeader",addOptions(){return{HTMLAttributes:{}}},content:"block+",addAttributes(){return{colspan:{default:1},rowspan:{default:1},colwidth:{default:null,parseHTML:t=>{const e=t.getAttribute("colwidth");const r=e?e.split(",").map((t=>parseInt(t,10))):null;return r}}}},tableRole:"header_cell",isolating:true,parseHTML(){return[{tag:"th"}]},renderHTML({HTMLAttributes:t}){return["th",e(this.options.HTMLAttributes,t),0]}});export{r as TableHeader,r as default};

