
// Extend the String interface to include 'splice'
declare global {
  interface String {
    splice(start: number, delCount: number, newSubStr: string): string;
  }
}

if (!String.prototype.splice) {
    /**
     * {JSDoc}
     *
     * The splice() method changes the content of a string by removing a range of
     * characters and/or adding new characters.
     *
     * @this {String}
     * @param {number} start Index at which to start changing the string.
     * @param {number} delCount An integer indicating the number of old chars to remove.
     * @param {string} newSubStr The String that is spliced in.
     * @return {string} A new string with the spliced substring.
     */
    String.prototype.splice = function(start: number, delCount: number, newSubStr: string): string {
        return this.slice(0, start) + newSubStr + this.slice(start + Math.abs(delCount));
    };
}





const notasArr = Deno.readTextFileSync(
  "/home/martincito/Documentos/epub/pez/assets/notas pez.txt",
)
  .split("\n")
  .map((str) => str.split("-->").map((el) => el.trim()));

let pez = Deno.readTextFileSync(
  "/home/martincito/Documentos/epub/pez/md/CHURATA, Gamaliel - El pez de oro (Canata, 2014).md",
);
const pezNoAccents = accentFold(pez);
const pezNoBold = pezNoAccents.replaceAll("**", "");

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
    valid.push([i, placement, textTooMatch.length])
    endNotes.push(footnote)
  }
  i++;
}



for(const [note, index, lenght] of valid.reverse()){
  pez = pez.splice(index+lenght, 0 , `[^${note}]` )
}

pez = pez + '\n\n' + endNotes.join('\n\n')

// Deno.writeTextFileSync("./malas.json", JSON.stringify(noMatch));
// Deno.writeTextFileSync("./noteado.md", pez);
// Deno.writeTextFileSync("./collisiones.json", JSON.stringify(collisioned));

function accentFold(inStr: string) {
  return inStr.replace(
    /([àáâãäå])|([çčć])|([èéêë])|([ìíîï])|([ñ])|([òóôõöø])|([ß])|([ùúûü])|([ÿ])|([æ])/g,
    function (str, a, c, e, i, n, o, s, u, y, ae) {
      if (a) return "a";
      if (c) return "c";
      if (e) return "e";
      if (i) return "i";
      if (n) return "n";
      if (o) return "o";
      if (s) return "s";
      if (u) return "u";
      if (y) return "y";
      if (ae) return "ae";
      return str;
    },
  );
}
