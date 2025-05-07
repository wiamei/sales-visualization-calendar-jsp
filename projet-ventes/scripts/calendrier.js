/*
 * Retourne la correspondance en lettres du mois passé en paramètre.
 *		1  -> Janvier
 *		2  -> Février
 *		...
 *		12 -> Décembre
 */
const moisEnLettres = (numMois) =>
  [
    "Janvier",
    "Février",
    "Mars",
    "Avril",
    "Mai",
    "Juin",
    "Juillet",
    "Août",
    "Septembre",
    "Octobre",
    "Novembre",
    "Décembre",
  ][numMois - 1];

/*
 * Calcule et retourne le nombre de jours du mois de l'année (passés en paramètres).
 *	1  -> 31
 *	2  -> (29 ou 28) Selon si l'année est bissextile ou pas
 *	3  -> 31
 *	4  -> 30
 *	...
 *	12 -> 31
 */
const getNbJours = (mois, annee) => {
  var nbJours = 31;
  // Calculer le nombre de jours que compte le mois de l'année entrées par l'utilisateur
  if (mois == 4 || mois == 6 || mois == 9 || mois == 11) {
    // Avril, Juin, Septembre ou Novembre : ces mois de l'année comptent 30 jours
    nbJours = 30;
  } else {
    if (mois == 2) {
      // Le mois de février compte 29 ou 28 jours selon si l'année est bissextile ou pas
      if ((annee % 4 == 0 && annee % 100 != 0) || annee % 400 == 0) {
        // Cette année est bissextile : Le mois de février compte 29 jours
        nbJours = 29;
      } else {
        // Cette année est normale (compte 365 jours)
        // Par conséquent : Le mois de février compte 28 jours
        nbJours = 28;
      }
    }
  }

  return nbJours;
};

/*
 * Calcule et retourne un chiffre [0,6] représentant le jour de la semaine correspondant à la date
 * passée en paramètre (jour, mois, année) :
 *		0 -> Dimanche
 *		1 -> Lundi
 *		2 -> Mardi
 *		3 -> Mercredi
 *		4 -> Jeudi
 *		5 -> Vendredi
 *		6 -> Samedi
 */
const jourDeSemaine = (jour, mois, annee) => {
  var ns, as, f;

  if (mois >= 3) mois -= 2;
  else {
    mois += 10;
    annee -= 1;
  }
  ns = Math.floor(annee / 100);
  as = annee % 100;
  f =
    (jour +
      as +
      Math.floor(as / 4) -
      2 * ns +
      Math.floor(ns / 4) +
      Math.floor((26 * mois - 2) / 10)) %
    7;

  if (f < 0) f = f + 7;

  return f;
};

/*
 * Calcule et retourne un chiffre [0,6] représentant le jour de la semaine correspondant au premier jour
 * du mois et de l'année passés en paramètres.
 * ! Pensez à appeler la fonction jourDeSemaine() définie précédemment au lieu de réinventer la roue.
 */
const premierJourDuMois = (mois, annee) => jourDeSemaine(1, mois, annee);

/*
 * Construit et retourne un tableau JS (Array) contenant les dates du mois de l'année passés en paramètre
 * Exemple :
 * 	Pour les valeurs ci-dessous (passées en paramètre)
 * 		mois  = 1
 *		annee = 2020
 *	la fonction retournera le tableau (Array) à deux dimensions ci-dessous représentant
 *  les dates organisées en semaines :
 *
 *	[[undefined, undefined, undefined, 1, 2, 3, 4],
 *	 [ 5,  6,  7,  8,  9, 10, 11]
 *	 [12, 13, 14, 15, 16, 17, 18]
 *	 [19, 20, 21, 22, 23, 24, 25]
 *	 [26, 27, 28, 29, 30, 31, empty]]
 *
 */
const getTableauCalendrier = (mois, annee) => {
  const premierJour = premierJourDuMois(mois, annee);
  const nbJours = getNbJours(mois, annee);

  const nbSemaines = Math.ceil((premierJour + nbJours) / 7);
  const datesCalendrier = new Array(nbSemaines);
  let date = 1;

  //Remplir les dates de la première semaine en laissant les cellules
  //vides au début du tableau lorsque le premier jour du mois n'est pas
  //un dimanche
  datesCalendrier[0] = new Array(7);
  for (let jour = premierJour; jour < 7; jour++) {
    datesCalendrier[0][jour] = date++;
  }

  //Remplir les semaine subséquentes
  //Pour la dernières semaine, lorsque le dernier jour n'est pas un samedi
  //laisser les cellules vides à la fin
  for (let noSemaine = 1; noSemaine < nbSemaines; noSemaine++) {
    datesCalendrier[noSemaine] = new Array(7);
    for (let jour = 0; jour < 7 && date <= nbJours; jour++) {
      datesCalendrier[noSemaine][jour] = date++;
    }
  }
  return datesCalendrier;
};

/*
 * Construit le sous-arbre DOM du document représentant un tableau (table) correspondant au calendrier du mois de
 * l'année passés en paramètres et retourne le noeud racine représentant cet arbre.
 */
const getArbreDOMCalendrier = (mois, annee, anneesRef) => {
  const joursSemaines = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"];
  const tableauCalendrier = getTableauCalendrier(mois, annee);
  const nbCellulesVidesDebut = premierJourDuMois(mois, annee);

  const getCellule = (j, m, a) => {
    let td = document.createElement("td");
    let anchor = document.createElement("a");
    anchor.setAttribute(
      "href",
      "./afficherVentes.jsp?j=" +
        j +
        "&m=" +
        m +
        "&a=" +
        a +
        "&aRef=" +
        anneesRef
    );
    anchor.setAttribute("class", "badge badge-pill badge-light");
    anchor.appendChild(document.createTextNode(j));
    td.appendChild(anchor);
    return td;
  };

  //Initialiser l'élément <table>
  let calendrier = document.createElement("table");
  calendrier.setAttribute(
    "class",
    "table table-bordered table-light table-striped text-center col-lg-6 mx-auto mb-0"
  );

  let caption = document.createElement("caption");
  caption.setAttribute(
    "class",
    "bg-dark text-light text-center font-weight-bold"
  );

  let baseHref = "./afficherVentes.jsp";

  let lienMois = document.createElement("a");
  lienMois.setAttribute(
    "href",
    baseHref + "?m=" + mois + "&a=" + annee + "&aRef=" + anneesRef
  );
  lienMois.setAttribute("class", "badge badge-dark");
  lienMois.appendChild(document.createTextNode(moisEnLettres(mois)));

  let lienAnnee = document.createElement("a");
  lienAnnee.setAttribute(
    "href",
    baseHref + "?a=" + annee + "&aRef=" + anneesRef
  );
  lienAnnee.setAttribute("class", "badge badge-dark");
  lienAnnee.appendChild(document.createTextNode(annee));

  caption.appendChild(lienMois);
  caption.appendChild(lienAnnee);
  calendrier.appendChild(caption);

  let thead = document.createElement("thead");
  thead.setAttribute("class", "thead-dark");

  let tr = document.createElement("tr");
  let th, span;

  joursSemaines.forEach(function (jour, noJour) {
    th = document.createElement("th");
    th.appendChild(document.createTextNode(jour));
    tr.appendChild(th);
  });

  thead.appendChild(tr);
  calendrier.appendChild(thead);

  let tbody = document.createElement("tbody");
  tr = document.createElement("tr");

  //Insréer les cellules pour la première semaine (la première rangée du tableau)
  if (nbCellulesVidesDebut > 0) {
    let td = document.createElement("td");
    td.setAttribute("class", "vide");
    td.setAttribute("colspan", nbCellulesVidesDebut);
    tr.appendChild(td);
  }

  for (let jour = nbCellulesVidesDebut; jour < 7; jour++) {
    tr.appendChild(getCellule(tableauCalendrier[0][jour], mois, annee));
  }

  tbody.appendChild(tr);

  //Insérer les cellules des semaines subséquentes sauf la dernière
  for (let semaine = 1; semaine < tableauCalendrier.length - 1; semaine++) {
    tr = document.createElement("tr");
    for (let jour = 0; jour < 7; jour++) {
      tr.appendChild(getCellule(tableauCalendrier[semaine][jour], mois, annee));
    }
    tbody.appendChild(tr);
  }

  //Insréer les cellules pour la dernière semaine (la première rangée du tableau)
  tr = document.createElement("tr");

  let derniereSemaine = tableauCalendrier[tableauCalendrier.length - 1];
  let nbCellulesVidesFin = 0;
  for (let jour = 0; jour < 7; jour++) {
    if (derniereSemaine[jour] == undefined) {
      nbCellulesVidesFin++;
      continue;
    }
    tr.appendChild(getCellule(derniereSemaine[jour], mois, annee));
  }

  if (nbCellulesVidesFin > 0) {
    let td = document.createElement("td");
    td.setAttribute("class", "vide");
    td.setAttribute("colspan", nbCellulesVidesFin);
    tr.appendChild(td);
  }

  tbody.appendChild(tr);

  calendrier.appendChild(tbody);
  return calendrier;
};
