const express=require("express");
const cors=require("cors");
const Parser=require("rss-parser");
const path=require("path");
const https=require("https");
const app=express(); const parser=new Parser({timeout:15000});
app.use(cors()); app.use(express.static(__dirname));
const allowedHost="www.yerepouni-news.com";
const ignoredCategories=new Set([
  "mobile home","newsletter","mailchimp","featured","uncategorized",
  "english","western armenian","eastern armenian","արեւմտահայերէն","արեւելահայերէն"
]);
function pickCategory(categories){
  const list=(categories||[]).filter(Boolean);
  const meaningful=list.find(c=>{
    const lower=c.trim().toLowerCase();
    if(ignoredCategories.has(lower)) return false;
    if(c===c.toUpperCase()&&/[Ա-Ֆ]/.test(c)) return false;
    return true;
  });
  return meaningful||list[0]||"";
}
app.get("/api/feed",async(req,res)=>{
  try{
    const u=new URL(req.query.url);
    if(u.hostname!==allowedHost) return res.status(400).json({error:"Only Yerepouni feeds are allowed"});
    const feed=await parser.parseURL(u.toString());
    const items=(feed.items||[]).map(i=>{
      const content=i["content:encoded"]||i.content||"";
      const imgMatch=content.match(/<img[^>]+src=["']([^"']+)["']/i);
      return{
        title:i.title||"",link:i.link||"",date:i.isoDate||i.pubDate||"",
        excerpt:i.contentSnippet||i.content||"",
        content,
        category:pickCategory(i.categories),
        image:i.enclosure?.url||((i["media:content"]||{}).$?.url)||(imgMatch?imgMatch[1]:"")
      };
    });
    res.json({title:feed.title||"",items});
  }catch(e){res.status(502).json({error:"Feed fetch failed",detail:e.message})}
});
// Yerepouni's WordPress search is slow (10s+) regardless of query params;
// cache results briefly server-side so repeat/shared searches are instant.
const searchCache=new Map();
const SEARCH_CACHE_TTL_MS=5*60*1000;
app.get("/api/search",async(req,res)=>{
  const q=(req.query.q||"").toString().trim();
  if(!q) return res.json({items:[]});
  const cached=searchCache.get(q);
  if(cached&&Date.now()-cached.at<SEARCH_CACHE_TTL_MS) return res.json(cached.data);
  try{
    const searchUrl=`https://${allowedHost}/wp-json/wp/v2/posts?search=${encodeURIComponent(q)}&per_page=12&_embed=1`;
    const r=await fetch(searchUrl);
    if(!r.ok) return res.status(502).json({error:"Search failed"});
    const posts=await r.json();
    const strip=html=>String(html||"").replace(/<[^>]*>/g," ").replace(/\s+/g," ").trim();
    const items=(Array.isArray(posts)?posts:[]).map(p=>{
      const media=p._embedded?.["wp:featuredmedia"]?.[0];
      const terms=(p._embedded?.["wp:term"]||[]).flat();
      const categoryNames=terms.filter(t=>t.taxonomy==="category").map(t=>t.name);
      const category=pickCategory(categoryNames);
      return{
        title:strip(p.title?.rendered),
        link:p.link||"",
        date:p.date_gmt?`${p.date_gmt}Z`:(p.date||""),
        excerpt:strip(p.excerpt?.rendered),
        content:p.content?.rendered||"",
        category,
        image:media?.source_url||""
      };
    });
    const data={items};
    searchCache.set(q,{at:Date.now(),data});
    res.json(data);
  }catch(e){res.status(502).json({error:"Search failed",detail:e.message})}
});
app.get("/api/article",async(req,res)=>{
  let u;
  try{u=new URL(req.query.url)}catch{return res.status(400).json({error:"Invalid url"})}
  if(u.hostname!==allowedHost) return res.status(400).json({error:"Only Yerepouni articles are allowed"});
  const slug=u.pathname.replace(/^\/+|\/+$/g,"").split("/").pop();
  if(!slug) return res.status(400).json({error:"Could not resolve article slug"});
  try{
    // No _embed here: it roughly doubles WordPress's response time and we
    // only need the full body — category/image are kept from the RSS item
    // the client already has.
    const apiUrl=`https://${allowedHost}/wp-json/wp/v2/posts?slug=${encodeURIComponent(slug)}&_fields=content`;
    const r=await fetch(apiUrl);
    if(!r.ok) return res.status(502).json({error:"Article fetch failed"});
    let text=await r.text();
    // The site's own newsfreak.php plugin emits PHP warnings before the
    // JSON body when the "author" field isn't requested; strip them.
    const jsonStart=text.indexOf("[");
    if(jsonStart>0) text=text.slice(jsonStart);
    const posts=JSON.parse(text);
    const p=Array.isArray(posts)?posts[0]:null;
    if(!p) return res.status(404).json({error:"Article not found"});
    res.json({content:p.content?.rendered||""});
  }catch(e){res.status(502).json({error:"Article fetch failed",detail:e.message})}
});
app.get("/api/image",(req,res)=>{
  let u;
  try{u=new URL(req.query.url)}catch{return res.status(400).end()}
  if(u.hostname!==allowedHost||u.protocol!=="https:") return res.status(400).end();
  https.get(u,upstream=>{
    if(upstream.statusCode!==200){res.status(502).end();return}
    res.set("Content-Type",upstream.headers["content-type"]||"image/jpeg");
    res.set("Cache-Control","public, max-age=86400");
    upstream.pipe(res);
  }).on("error",()=>res.status(502).end());
});
app.listen(process.env.PORT||3000,()=>console.log("Yerepouni app running on http://localhost:"+(process.env.PORT||3000)));
