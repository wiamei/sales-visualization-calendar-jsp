window.addEventListener("load", () => {
  /*
   * Après le chargement de la page web :
   *	1- Récupérer le mois et l'année courants
   *  2- Récupérer la liste déroulante pour la sélection du mois, la remplir dynamiquement avec toutes les options
   *	   et sélectionner celle représentant le mois courant.
   *	3- Récupérer dynamiquement la zone de texte du formulaire et lui attribuer la valeur correspondante à l'année
   *     courante.
   *	4- Compléter la sous-fonction "updateCalendar" servant de gestionnaire d'évènement et permettant d'attacher
   *     à la page web le nouvel arbre DOM créé par la fonction "getArbreDOMCalendrier".
   *  5- Appeler la fonction manuellement pour un affichage initial correspondant à la date sélectionnée.
   *  6- Inscrire les éléments du formulaire aux différents évènements permettant la mise-à-jour du calendrier.
   */

  const ANNEES_REF = 3;

  let mois;
  let annee;

  //Ouvrir automatiquement la fenêtre modale d'aide losrque le paramètre error de l'URL est renseigné
  //et que sa valeur est : invalidParams
  const error = window.location.search.substring(1).split("&")[0].split("=");
  let strTitreAideModale;
  if (error[0] == "error" && error[1] == "invalidParams") {
    $("#aideModale").modal();
  }

  //Préparation du formulaire
  (() => {
    //Rcupérer la date courante
    const aujourdhui = new Date();
    mois = aujourdhui.getMonth();
    annee = aujourdhui.getFullYear();

    //Rcupérer la liste déroulante selectMois
    let selectMois = document.getElementById("selectMois");
    //Rcupérer la zone de texte inputAnnee
    let inputAnnee = document.getElementById("inputAnnee");

    //Ajouter dynamiquement les options du select
    //Cahque option représente l'un des douze mois de l'année
    for (let i = 1; i < 13; i++) {
      selectMois.appendChild(new Option(moisEnLettres(i), i));
    }

    //Mettre le mois courant comme valeur par défaut
    selectMois.selectedIndex = mois;

    //Mettre l'année courante comme valeur par défaut
    inputAnnee.value = annee;
  })();

  const updateCalendar = () => {
    mois = parseInt(document.getElementById("selectMois").value);
    annee = parseInt(document.getElementById("inputAnnee").value);

    if (!isNaN(mois) && !isNaN(annee)) {
      if (document.getElementById("calendrier").firstElementChild)
        document.getElementById("calendrier").firstElementChild.remove();
      document
        .getElementById("calendrier")
        .appendChild(getArbreDOMCalendrier(mois, annee, ANNEES_REF));
    }
  };

  //Construire manuellement le calendrier pour un affichage initial correspondant à la date sélectionnée
  updateCalendar();

  //Inscrire les composantes du formulaire aux différents évènements
  document
    .getElementById("selectMois")
    .addEventListener("change", updateCalendar);
  document
    .getElementById("inputAnnee")
    .addEventListener("input", updateCalendar);
  //document.getElementById("inputAnnee").addEventListener("keydown", updateCalendar);
  //document.getElementById("inputAnnee").addEventListener("keyup"  , updateCalendar);
});
