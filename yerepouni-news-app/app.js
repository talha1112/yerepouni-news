const state={lang:"western",menu:false,view:"home",category:null,search:false,query:"",prevMain:""};
let cfg;
const articleCache={};

const BOOKMARK_KEY="yerepouni_bookmarks";
function loadBookmarks(){try{return JSON.parse(localStorage.getItem(BOOKMARK_KEY))||{}}catch{return{}}}
function saveBookmarks(b){try{localStorage.setItem(BOOKMARK_KEY,JSON.stringify(b))}catch{}}
function isBookmarked(url){return !!loadBookmarks()[url]}
function toggleBookmark(url){
  const b=loadBookmarks();
  if(b[url])delete b[url]; else if(articleCache[url])b[url]=articleCache[url];
  saveBookmarks(b);
}

const esc=s=>String(s??"").replace(/[&<>"']/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"}[m]));
function stripHtml(s){const d=document.createElement("div");d.innerHTML=s||"";return d.textContent||d.innerText||""}
function dateFmt(s){try{return new Intl.DateTimeFormat("hy",{day:"numeric",month:"long",year:"numeric"}).format(new Date(s))}catch{return s}}
function catsFor(lang){return cfg.categories.filter(x=>x.language===lang)}
function langLabel(){return cfg.languages.find(x=>x.id===state.lang)?.label||""}
function rssUrlForCurrent(){
  if(state.category) return state.category.rss;
  return cfg.languages.find(x=>x.id===state.lang)?.general;
}
function proxyUrl(url){return `/api/feed?url=${encodeURIComponent(url)}`}

async function fetchFeed(url,limit=12){
  const r=await fetch(proxyUrl(url)); if(!r.ok) throw new Error("Feed unavailable");
  return await r.json();
}
function itemCard(x){
  const img=x.image||"";
  return `<article class="card" data-url="${esc(x.link)}">
    <div class="thumb">${img?`<img src="${esc(img)}" loading="lazy">`:""}</div>
    <div class="cardText"><span class="tag">${esc(x.category||"News")}</span>
    <button class="bookmarkBtn ${isBookmarked(x.link)?"on":""}" data-url="${esc(x.link)}" onclick="event.stopPropagation();onBookmarkClick(this)">${isBookmarked(x.link)?"★":"☆"}</button>
    <h3>${esc(x.title)}</h3><div class="meta">${esc(dateFmt(x.date))}</div>
    <p>${esc(stripHtml(x.excerpt||x.content).slice(0,150))}</p></div></article>`
}
function onBookmarkClick(btn){
  const url=btn.dataset.url;
  toggleBookmark(url);
  const on=isBookmarked(url);
  btn.classList.toggle("on",on);
  btn.textContent=on?"★":"☆";
  if(state.view==="bookmarks"&&!on)goBookmarks();
}
function renderShell(content){
 document.getElementById("app").innerHTML=`<div class="phone">
<header><button class="topbtn" onclick="toggleMenu()">☰</button><img src="${cfg.brand.logo}" class="logo"><button class="topbtn" onclick="toggleSearch()">⌕</button></header>
<main>${content}</main>
<nav class="bottom"><button class="${state.view==="home"?"active":""}" onclick="goHome()">⌂<small>Home</small></button>
<button class="${state.view==="latest"?"active":""}" onclick="goLatest()">▤<small>Latest</small></button>
<button class="${state.view==="bookmarks"?"active":""}" onclick="goBookmarks()">☆<small>Saved</small></button>
<button onclick="toggleMenu()">☰<small>Menu</small></button></nav>
<div id="drawer" class="backdrop ${state.menu?"show":""}" onclick="closeMenu()"><aside class="drawer" onclick="event.stopPropagation()">
<div class="drawerHead"><img src="${cfg.brand.logo}"><button onclick="closeMenu()">×</button></div>
<div class="drawerBody"><div class="menuLabel">LANGUAGES & CATEGORIES</div>
${cfg.languages.map(l=>`<section class="lang"><button class="langBtn" onclick="selectLang('${l.id}')">${esc(l.label)} <b>›</b></button>
<div class="cats ${state.lang===l.id&&state.menuOpenLang===l.id?"open":""}">${catsFor(l.id).map(c=>`<button onclick='openCategory(${JSON.stringify(c)})'>${esc(c.name)}</button>`).join("")}</div></section>`).join("")}
<button class="special" onclick="openToday()">ՊԱՏՄՈՒԹԵԱՆ ՄԷՋ ԱՅՍՕՐ</button>
<div class="menuFooter"><a href="${cfg.contact}" target="_blank">Contact Us</a><a href="${cfg.website}" target="_blank">Website</a><a href="${cfg.facebook}" target="_blank">Facebook</a></div>
</div></aside></div></div>`;
}
async function home(){
 state.view="home"; state.category=null;
 renderShell(`<div class="edition">${esc(langLabel())}</div><h1>Yerepouni News</h1><div id="featured"><div class="loading">Loading featured news…</div></div><section class="section"><h2>Latest News</h2></section><div id="feed"><div class="loading">Loading news…</div></div>`);
 try{const f=await fetchFeed(cfg.featured,5);document.getElementById("featured").innerHTML=featured(f.items||[]);document.querySelector(".hero")?.addEventListener("click",e=>openArticle(e.currentTarget.dataset.url))}
 catch{document.getElementById("featured").innerHTML=`<div class="error">Featured News could not be loaded.</div>`}
 try{const f=await fetchFeed(rssUrlForCurrent(),15);renderItems(f.items||[])}
 catch{document.getElementById("feed").innerHTML=`<div class="error">The live feed could not be loaded. Make sure the feed proxy is running.</div>`}
}
function featured(items){
 if(!items.length)return `<div class="error">No featured articles.</div>`;
 const x=items[0];
 articleCache[x.link]=x;
 return `<section class="hero" data-url="${esc(x.link)}"><img src="${esc(x.image||"")}" onerror="this.style.display='none'"><div><span class="tag">${esc(x.category||"Featured")}</span><h2>${esc(x.title)}</h2><p>${esc(stripHtml(x.excerpt||"").slice(0,120))}</p><small>${esc(dateFmt(x.date))}</small></div></section>`
}
function renderItems(items){
 const el=document.getElementById("feed"); if(!el)return;
 items.forEach(x=>{articleCache[x.link]=x});
 let out="";
 items.forEach((x,i)=>{if(i>0&&i%5===0)out+=`<div class="ad"><img src="${cfg.brand.ad}" alt="AFHIL"></div>`;out+=itemCard(x)});
 el.innerHTML=out||`<div class="error">${state.view==="bookmarks"?"No saved articles yet. Tap ☆ on any article to save it.":"No articles found."}</div>`;
 el.querySelectorAll(".card").forEach(c=>c.onclick=()=>openArticle(c.dataset.url))
}
async function goLatest(){state.view="latest";state.category=null;renderShell(`<div class="edition">${esc(langLabel())}</div><h1>Latest News</h1><div id="feed"><div class="loading">Loading…</div></div>`);try{const f=await fetchFeed(rssUrlForCurrent(),30);renderItems(f.items||[])}catch{document.getElementById("feed").innerHTML=`<div class="error">Feed unavailable.</div>`}}
function goBookmarks(){
 state.view="bookmarks";state.category=null;
 const items=Object.values(loadBookmarks());
 renderShell(`<h1>Saved Articles</h1><div id="feed"></div>`);
 renderItems(items);
}
async function openCategory(c){state.menu=false;state.view="category";state.category=c;renderShell(`<div class="edition">${esc(c.languageLabel)}</div><h1>${esc(c.name)}</h1><div id="feed"><div class="loading">Loading…</div></div>`);try{const f=await fetchFeed(c.rss,30);renderItems(f.items||[])}catch{document.getElementById("feed").innerHTML=`<div class="error">Category feed unavailable.</div>`}}
function openArticle(url){
 const x=articleCache[url]; if(!x)return;
 state.prevMain=document.querySelector("main")?.innerHTML||"";
 state.prevView=state.view; state.view="reader";
 renderShell(reader(x));
}
function reader(x){
 const img=x.image||"";
 const body=x.content||x.excerpt||"";
 return `<div class="readerTop"><button class="backbtn" onclick="closeReader()">‹ Back</button>
 <button class="bookmarkBtn readerBookmark ${isBookmarked(x.link)?"on":""}" data-url="${esc(x.link)}" onclick="onBookmarkClick(this)">${isBookmarked(x.link)?"★":"☆"}</button></div>
 ${img?`<img class="readerImg" src="${esc(img)}">`:""}
 <span class="tag">${esc(x.category||"News")}</span>
 <h1>${esc(x.title)}</h1>
 <div class="meta">${esc(dateFmt(x.date))}</div>
 <div class="readerBody">${body}</div>
 <a class="readerLink" href="${esc(x.link)}" target="_blank" rel="noopener">Read full article on Yerepouni News ›</a>`
}
function closeReader(){
 state.view=state.prevView||"home";
 renderShell(state.prevMain);
 document.querySelectorAll(".card").forEach(c=>c.onclick=()=>openArticle(c.dataset.url));
 document.querySelector(".hero")?.addEventListener("click",e=>openArticle(e.currentTarget.dataset.url));
}
function selectLang(id){state.lang=id;state.menuOpenLang=state.menuOpenLang===id?null:id;state.category=null;renderShell(document.querySelector("main")?.innerHTML||"");}
function toggleMenu(){state.menu=!state.menu;renderShell(document.querySelector("main")?.innerHTML||"")}
function closeMenu(){state.menu=false;renderShell(document.querySelector("main")?.innerHTML||"")}
function toggleSearch(){const q=prompt("Search Yerepouni News");if(q)alert("Search UI will be connected to WordPress search next.")}
function goHome(){home()}
async function openToday(){state.menu=false;state.view="today";state.category=null;renderShell(`<h1>ՊԱՏՄՈՒԹԵԱՆ ՄԷՋ ԱՅՍՕՐ</h1><div id="feed"><div class="loading">Loading…</div></div>`);try{const f=await fetchFeed(cfg.todayInHistory,30);renderItems(f.items||[])}catch{document.getElementById("feed").innerHTML=`<div class="error">Feed unavailable.</div>`}}
fetch("config.json").then(r=>r.json()).then(c=>{cfg=c;home()});
