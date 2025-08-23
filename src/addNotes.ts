import * as path from "jsr:@std/path";

const currentDir = path.dirname(path.fromFileUrl(import.meta.url));
const notasArr = Deno.readTextFileSync(
  path.join(currentDir, "..", "assets", "notas pez.txt")
)
  .split("\n")
  .map((str) => str.split("-->").map((el) => el.trim()));

let pez = Deno.readTextFileSync(
  path.join(currentDir, "..", "md", "CHURATA, Gamaliel - El pez de oro (Canata, 2014).md")
);
const pezNoAccents = accentFold(pez);

let i = 1;

const noMatch = [];
const collisioned = [];

const valid = []
const endNotes = []

for (const [textTooMatch, footnote] of notasArr) {

  const cleanSubStr = accentFold(textTooMatch);
  const exist = pezNoAccents.includes(cleanSubStr);

  
  if (!exist) {
    noMatch.push([i, textTooMatch]);
  }

  const matches = pezNoAccents.split(cleanSubStr);

  if (matches.length > 2) {
    collisioned.push([i, textTooMatch, matches.length]);
  }

  if(exist && !(matches.length > 2) ){
    const placement = pezNoAccents.indexOf(cleanSubStr);
    valid.push([i, placement, cleanSubStr.length])
  }

  endNotes.push(footnote)
  i++;
}


const r = valid.sort(( a,b ) => b[1] - a[1])

for(const [note, index, length] of r){
  const addition = `[^${note}]`

  pez = pez.slice(0, index + length ) + addition + pez.slice(index + length);
}

pez = pez + '\n\n' + endNotes.join('\n\n')

// Deno.writeTextFileSync("./malas.json", JSON.stringify(noMatch));
// Deno.writeTextFileSync("./noteado.md", pez);
// Deno.writeTextFileSync("./collisiones.json", JSON.stringify(collisioned));

function accentFold(inStr: string) {
  return inStr.replace(
    /([àáâãäå])|([çčć])|([èéêë])|([ìíîï])|([ñ])|([òóôõöø])|([ùúûü])|([ÿ])|/g,
    function (str, a, c, e, i, n, o, u, y,) {
      if (a) return "a";
      if (c) return "c";
      if (e) return "e";
      if (i) return "i";
      if (n) return "n";
      if (o) return "o";
      if (u) return "u";
      if (y) return "y";
      return str;
    },
  );
}