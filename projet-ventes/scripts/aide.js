/*
 * Permet de créer l'arbre DOM représentant le corps de la fenêtre modale d'aide et le retourne.
 * Ce dernier est sous forme d'une liste de définitions (Élément HTML "dl") renfermant la liste des fonctionnalités.
 * Les termes (les éléments "dt" de la liste) représentent les actions de l'utilisateurs alors que leurs définitions
 * (les éléments "dd" de la liste)  représentent le résultat escompté.
 */

const getCorpsFenetreAide = () => {
  let fonctionnalites = [
    {
      action: "Clic sur le mois",
      resultat:
        "Permet de comparer le total des ventes réalisées au cours du mois de l'année sélectionnés à celui du même mois des années précédentes.",
    },
    {
      action: "Clic sur l'année",
      resultat:
        "Permet de comparer le total des ventes réalisées au cours de l'année sélectionnée à celui des années précédentes",
    },
    {
      action: "Clic sur une date précise",
      resultat:
        "Permet de comparer le total des ventes réalisées au cours de cette date à celui de la même date des années précédentes",
    },
  ];

  let dl = document.createElement("dl");
  dl.className = "row";

  let dt, dd;

  const dtNbCols = 4;
  const ddNbCols = 12 - dtNbCols;

  for (fonctionnalite of fonctionnalites) {
    dt = document.createElement("dt");
    dt.className = `col-md-${dtNbCols}`;
    dt.appendChild(document.createTextNode(fonctionnalite.action));

    dd = document.createElement("dd");
    dd.className = `col-md-${ddNbCols}`;
    dd.appendChild(document.createTextNode(fonctionnalite.resultat));

    dl.appendChild(dt);
    dl.appendChild(dd);
  }

  return dl;
};

window.addEventListener("load", () => {
  //Remplir le corps de la fenêtre modale d'aide
  document.getElementById("corps-aide").appendChild(getCorpsFenetreAide());
});
