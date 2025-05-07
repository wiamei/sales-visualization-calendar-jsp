<!-- Importation des classes Java -->
<%@page import="java.util.Vector"%>
<%@page import="java.util.Iterator"%>
<%@page import="java.io.IOException"%>
<%@page import="java.io.FileNotFoundException"%>
<%@page import="java.util.Hashtable"%>
<%@page import="java.io.BufferedReader"%>
<%@page import="java.io.FileReader"%>
<%@page import="java.io.File"%>
<%@page import="java.util.Map"%>

<%@page import="java.io.InputStreamReader"%>
<%@page import="java.io.FileInputStream"%>

<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
  
<%!

/**
 * Declaration des constantes representant les noms de parametres de la requete HTTP.
 **/ 
 public static final String JOUR_PARAM = "j";
 public static final String MOIS_PARAM = "m";
 public static final String ANNEE_PARAM = "a";
 public static final String ANNEES_REF_PARAM = "aRef";
 
/**
 * Declaration des constantes representant les differents niveaux de granularite pour l'agregation des ventes.
 **/

 public static final int PRECISION_ND = -1;
 public static final int PRECISION_JOUR = 1;
 public static final int PRECISION_MOIS = 2;
 public static final int PRECISION_ANNEE = 3;
 
/**
 * Declaration des constantes representant les valeurs des trois composantes (rouge, verte et bleue) de la couleur
 **/
 public static final int COULEUR_R = 23;
 public static final int COULEUR_V = 162;
 public static final int COULEUR_B = 184;
 
/**
 * Declaration de la constante definissant le lien (path) relatif vers le fichier de donnees : "data/ventes.log"
 **/

 public static final String CHEMIN_FICHIER_VENTES = "data/ventes.log";

/**
 * Extrait et retourne le parametre de l'URL.
 * Les parametres de l'URL sont parmi les suivantes :
 * 		ANNEES_REF_PARAM, ANNEE_PARAM, MOIS_PARAM et JOUR_PARAM.
 * Retourne la valeur correspondante si cette derniere a ete renseignee, 3 ou -1 sinon.
 * 		 3 pour aRef lorsque ce dernier n'a pas ete renseigne.
 *		-1 pour j, m ou a lorsque le parametre n'a pas ete renseigne.
 **/
 
 public int extraireParam(HttpServletRequest request, String paramKey) {
	    // R�cup�rer la valeur du param�tre depuis la requ�te HTTP
	    String paramValue = request.getParameter(paramKey);
	    System.out.println("DEBUG: paramKey=" + paramKey + ", paramValue=" + paramValue); 
	    
	    // V�rifier si la valeur existe et n'est pas vide
	    if (paramValue != null && !paramValue.isEmpty()) {
	        try {
	            // Tenter de convertir la valeur en entier et la retourner
	            return Integer.parseInt(paramValue);
	        } catch (NumberFormatException e) {
	            // En cas d'erreur de conversion, afficher un message d'erreur et retourner -1
	            System.out.println("ERROR: Invalid number for " + paramKey + "=" + paramValue);
	            return -1;
	        }
	    } else {
	        // Si le param�tre n'est pas pr�sent ou est vide, retourner -1
	        return -1;
	    }
	}

/**
 * Retourne une chaine de caracteres representant la date passee en parametre.
 * Exemples :
 *		jour=25, mois=2 , annee=2025	>>	pour le 25 Fevrier 2025
 *		jour=-1, mois=2 , annee=2025	>>	pour Fevrier 2025
 *		jour=-1, mois=-1, annee=2025	>>	de l'annee 2025
 **/

 public String dateEnLettres(int jour, int mois, int annee) {
    String [] moisEnLettres = {"", "Janvier", "Fevrier", "Mars", "Avril", "Mai", "Juin", "Juillet", "Aout", "Septembre", "Octobre", "Novembre", "Decembre"};
    if (mois == -1 ) {
        return "de l'annee " + annee;
    } else if (jour == -1) {
        return "pour " + moisEnLettres[mois] + " " + annee ;
    } else {
        return "pour le " + jour + " " + moisEnLettres[mois] + " " + annee ;
    }

  }

 /**
  * Determine et retourne le niveau de granularite en fonction des parametres de l'URL
  * Scenario 1 : Toutes les donnees ont ete renseignees (jourDemande, moisDemande et anneeDemandee), la fonction retourne PRECISION_JOUR
  * Scenario 2 : Seulement le mois et l'annee ont ete renseignes (jourDemande = -1), la fonction retourne PRECISION_MOIS
  * Scenario 3 : Seulement l'annee a ete renseignee (jourDemande = -1 et moisDemande = -1), la fonction retourne PRECISION_ANNEE
  * Scenario 4 : Aucune donnee n'a ete renseignee (jourDemande = -1, moisDemande = -1 et anneeDemande = -1), la fonction retourne PRECISION_ND
  **/
  
public int determinerGranularite(int jourDemande, int moisDemande, int anneeDemandee) {	
    if (anneeDemandee == -1) {
        return PRECISION_ND;
    }
    if (jourDemande != -1 && moisDemande != -1) {
        return PRECISION_JOUR;
    }
    if (moisDemande != -1) {
        return PRECISION_MOIS;
    }
    return PRECISION_ANNEE;
 }

/**
 * Recoit deux vecteurs (Vector<String> dates et Vector<Double> montants) a remplir avec les donnees lues dans un fichier texte dont l'URL "relative" 
 * est passee en parametre (fileRelativeURL).
 * Les donnees extraites du fichier correspondent a toutes les donnees respectant la date passee en parametre
 * (joursDemande/moisDemande) pour toutes les annees appartenant  l'intervalle [anneeDemandee-anneesRefDemandees, anneeDemandee])
 * Peu importe la granularite demandee, chacune des entrees dans les deux vecteurs (dates et montants) correspond aux donnes d'une ligne du fichier texte.
 * Neanmoins, la granularite sert a atendre la selection des lignes a prendre en consideration.
 * En fonction du parametre (int granularite), quatre scenarios d'extractions sont possibles :
 * 		Scenario 1 (PRECISION_JOUR) : Une date precise a ete demandee + la meme date pour toutes les annees de reference.
 *		Scenario 2 (PRECISION_MOIS) : Toutes les dates d'un mois d'une annee + toutes celles du meme mois pour toutes les annees de reference.
 *		Scenario 3 (PRECISION_ANNEE): Toutes les dates d'une annee + celles des annees de reference.
 *		Scenario 4 (PRECISION_ND)   : Aucune vente ne sera extraite.
 **/
 
 public void extraireDonneesDansVecteurs(ServletContext app, String fileRelativeURL,
	        int jourDemande, int moisDemande, int anneeDemandee, int anneesRefDemandees, int granularite,
	        Vector<String> dates, Vector<Double> montants)
	    throws FileNotFoundException, IOException {

	    // Si la granularit� n'est pas d�finie, il n'y a pas de donn�es � extraire.
	    if (granularite == PRECISION_ND) {
	        return;
	    }
	    
	    // R�soudre le chemin r�el du fichier de donn�es
	    File dataFile = new File(app.getRealPath(fileRelativeURL));
	    BufferedReader reader = new BufferedReader(new FileReader(dataFile));
	    
	    // Calcul de l'intervalle d'ann�es � traiter : [ann�eDemandee - anneesRefDemandees, ann�eDemandee]
	    int anneeDebut = anneeDemandee - Math.max(anneesRefDemandees, 0);
	    int anneeFin = anneeDemandee;
	    
	    // Option pour ignorer l'en-t�te du fichier
	    boolean skipFileHeader = true;
	    if (skipFileHeader) {
	        reader.readLine(); 
	    }
	    
	    // Lecture du fichier ligne par ligne
	    String line;
	    while ((line = reader.readLine()) != null) {
	        String[] parts = line.split("\t");
	        // Ignorer la ligne si elle ne comporte pas au moins 2 parties (date et montant)
	        if (parts.length < 2) continue;
	        
	        // R�cup�ration de la date et du montant � partir de la ligne
	        String date = parts[0];
	        double montant = Double.parseDouble(parts[1]);
	        
	        // D�coupage de la date en ses composantes (ann�e, mois, jour)
	        String[] dateParts = date.split("-");
	        int annee = Integer.parseInt(dateParts[0]);
	        int mois = (dateParts.length > 1) ? Integer.parseInt(dateParts[1]) : -1;
	        int jour = (dateParts.length > 2) ? Integer.parseInt(dateParts[2]) : -1;
	        
	        // V�rifier si l'ann�e de l'enregistrement est dans l'intervalle souhait�
	        if (annee >= anneeDebut && annee <= anneeFin) {
	            // S�lectionner les lignes selon le niveau de granularit� demand�
	            if ((granularite == PRECISION_ANNEE) ||
	                (granularite == PRECISION_MOIS && mois == moisDemande) ||
	                (granularite == PRECISION_JOUR && mois == moisDemande && jour == jourDemande)) {
	                
	                // Normalisation de la date en fonction de la granularit�
	                String normalizedDate = "";
	                if (granularite == PRECISION_ANNEE) {
	                    normalizedDate = "" + annee;
	                } else if (granularite == PRECISION_MOIS) {
	                    // Format "AAAA-MM" (exemple : "2020-02")
	                    normalizedDate = annee + "-" + (mois < 10 ? "0" + mois : mois);
	                } else if (granularite == PRECISION_JOUR) {
	                    // Format "AAAA-MM-JJ" (exemple : "2020-02-05")
	                    normalizedDate = annee + "-" + (mois < 10 ? "0" + mois : mois) + "-" + (jour < 10 ? "0" + jour : jour);
	                }
	                
	                // Ajouter la date normalis�e et le montant dans les vecteurs
	                dates.add(normalizedDate);
	                montants.add(montant);
	            }
	        }
	    }
	    // Fermer le lecteur du fichier
	    reader.close();
	}



 
 public Hashtable<String, Double> totauxAgreges(Vector<String> dates, Vector<Double> montants, int granularite) {
		Hashtable<String, Double> totalParGranularite = new Hashtable<String, Double>();
		String date, dateCle;
		if (granularite == PRECISION_ND) {
			return totalParGranularite;
		}
	
		// Parcourir les vecteurs dates et montants
		for (int i = 0; i < dates.size(); i++) {
			date = dates.get(i);
			double montant = montants.get(i);
	
			// Extraire les composantes de la date
			String[] dateParts = date.split("-");
		    
			if (granularite == PRECISION_JOUR){
				dateCle = dateParts[0] + "-" + dateParts[1] + "-" + dateParts[2];
			} else if (granularite == PRECISION_MOIS){
				dateCle = dateParts[0] + "-" + dateParts[1];
			} else if (granularite == PRECISION_ANNEE){
				dateCle = dateParts[0] ;
			} else {
				continue;
			}
			if (totalParGranularite.containsKey(dateCle)) {
				//Si la date existe deja dans le hashtable , ajouter le montant
				double totalActuel = totalParGranularite.get(dateCle);
				totalParGranularite.put(dateCle,totalActuel + montant);
			} else {
				//Sinon ajouter la date et le montant
				totalParGranularite.put(dateCle,montant);
			}
		}
		return totalParGranularite;		
 }


public void remplirVides(Vector<String> dates, int jourDemande, int moisDemande, int anneeDemandee, int anneesRefDemandees, int granularite) {
	    // Determiner l'intervalle des annees a traiter
	    int anneeDebut = anneeDemandee - anneesRefDemandees;
	    int anneeFin = anneeDemandee;

	    // Creer une table de hachage pour stocker les dates existantes
	    Hashtable<String, Boolean> datesExistantes = new Hashtable<>();
	    for (String date : dates) {
	        datesExistantes.put(date, true);
	    }

	    // Ajouter les dates manquantes selon la granularite
	    if (granularite == PRECISION_JOUR) {
	        for (int annee = anneeDebut; annee <= anneeFin; annee++) {
	            String dateFormatee = annee + "-";
	            // Ajouter le mois
	            if (moisDemande < 10) {
	                dateFormatee += "0" + moisDemande + "-";  // Mois avec un zero si necessaire
	            } else {
	                dateFormatee += moisDemande + "-";
	            }
	            // Ajouter le jour
	            if (jourDemande < 10) {
	                dateFormatee += "0" + jourDemande;  // Jour avec un zero si necessaire
	            } else {
	                dateFormatee += jourDemande;
	            }
	            // Verifier et ajouter la date si elle n'existe pas
	            if (!datesExistantes.containsKey(dateFormatee)) {
	                dates.add(dateFormatee);
	                datesExistantes.put(dateFormatee, true);
	            }
	        }
	    } else if (granularite == PRECISION_MOIS) {
	        for (int annee = anneeDebut; annee <= anneeFin; annee++) {
	            String dateFormatee = annee + "-";
	            // Ajouter le mois
	            if (moisDemande < 10) {
	                dateFormatee += "0" + moisDemande;  // Mois avec un zero si necessaire
	            } else {
	                dateFormatee += moisDemande;
	            }
	            // Verifier et ajouter la date si elle n'existe pas
	            if (!datesExistantes.containsKey(dateFormatee)) {
	                dates.add(dateFormatee);
	                datesExistantes.put(dateFormatee, true);
	            }
	        }
	    } else if (granularite == PRECISION_ANNEE) {
	        for (int annee = anneeDebut; annee <= anneeFin; annee++) {
	            String dateFormatee = String.valueOf(annee);
	            // Verifier et ajouter la date si elle n'existe pas
	            if (!datesExistantes.containsKey(dateFormatee)) {
	                dates.add(dateFormatee);
	                datesExistantes.put(dateFormatee, true);
	            }
	        }
	    }
	}


 
/**
 * Trie le vecteur (Vector<String> dates) recu en parametre par ordre ascendant des dates.
 **/
 public void trierDates(Vector<String> dates) {
	    // Implementation du tri par bulle
	    int nb_echanges = -1;  // Initialiser le nombre d'echanges a -1 pour commencer la boucle
	    while (nb_echanges != 0) {
	        nb_echanges = 0;  // Reinitialiser le nombre d'echanges a chaque passage
	        // Parcourir le vecteur
	        for (int i = 0; i < dates.size() - 1; i++) {
	            // Recuperer les dates en format chaine de caracteres
	            String date1 = dates.get(i);
	            String date2 = dates.get(i + 1);
	            
	            // Convertir les dates String en int
	            int date1Int = Integer.parseInt(date1.replace("-", ""));
	            int date2Int = Integer.parseInt(date2.replace("-", ""));

	            // Comparer les dates sous forme d'entiers
	            if (date1Int > date2Int) {
	                // Si la premiere date est plus grande, on echange les deux dates
	                String tempSt = dates.get(i);
	                dates.set(i, dates.get(i + 1));
	                dates.set(i + 1, tempSt);
	                nb_echanges++;  // Incrementer le nombre d'echanges
	            }
	        }
	    }
}

 public String[] toChartJSData(Hashtable<String, Double> totauxAgreges,  
	        Vector<String> datesTriees, 
	        int coulR, int coulV, int coulB) {
	    
	    // Utiliser le vecteur de dates tri�es qui contient d�sormais
	    // toutes les dates (m�me celles sans vente, pour lesquelles le montant sera 0).
	    int n = datesTriees.size();
	    StringBuilder labels = new StringBuilder("[");
	    StringBuilder data = new StringBuilder("[");
	    StringBuilder colors = new StringBuilder("[");
	    
	    for (int i = 0; i < n; i++) {
	        String date = datesTriees.get(i);
	        // Si la date n'est pas pr�sente dans totauxAgreges, utiliser 0
	        double montant = totauxAgreges.containsKey(date) ? totauxAgreges.get(date) : 0;
	        
	        // Construire le label et la valeur
	        labels.append("\"").append(date).append("\"");
	        data.append(Math.round(montant));
	        
	        // Calculer l'opacit� :
	        // Si une seule colonne, opacit� = 1,
	        // Sinon, pour i allant de 0 � n-1, opacit� = (i+1)/n.
	        double opacity = (n == 1) ? 1.0 : ((i + 1) / (double)n);
	        String opacityStr = String.format("%.2f", opacity);
	        
	        // Construire la couleur au format "rgba(coulR, coulV, coulB, opacit�)"
	        colors.append("\"rgba(")
	              .append(coulR).append(",")
	              .append(coulV).append(",")
	              .append(coulB).append(",")
	              .append(opacityStr).append(")\"");
	        
	        if (i < n - 1) {
	            labels.append(",");
	            data.append(",");
	            colors.append(",");
	        }
	    }
	    
	    labels.append("]");
	    data.append("]");
	    colors.append("]");
	    
	    return new String[] { labels.toString(), data.toString(), colors.toString() };
	}

%>

<!DOCTYPE html>
<html>
<head>
    <!-- Balises meta requises -->
    <meta charset="ISO-8859-1">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <!-- CSS de Bootstrap-->
    <link rel="stylesheet"
          href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css"
          integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh"
          crossorigin="anonymous">
    
    <style>
	@media screen and (min-width: 992px) and (max-width: 1199px) {
		h1#titre {font-size: 4em;}
	}
	@media screen and (max-width: 991px) {
		h1#titre {font-size: 3em;}
	}
	@media screen and (max-width: 575px) {
		h1#titre {font-size: 2em;}
	}
	span#date {font-size: 2em;}
	</style>

<title>Affichage des ventes</title>
<script src="https://kit.fontawesome.com/622b0c0fcc.js" crossorigin="anonymous"></script>
</head>
<body>
	<div class="container-md">
		<header  class="text-center bg-dark text-light p-1 mb-3">
			<button id="backBtn" type="button" class="btn btn-info sticky-top" style="float: left;">
				<i class="fas fa-arrow-circle-left"></i>
			</button>
			
			<h1 id="titre" class="display-1 ">Visualisation des ventes</h1>
			<div class="badge badge-info w-100"><span id="date">
			<%
				// Extraction des differents parametres de l'URL
				// Utiliser la fonction extraireParam()
				
				// Extraire le parametre de l'annee de reference
			    int anneesRef = extraireParam(request, ANNEES_REF_PARAM);
			    // Extraire le parametre de l'annee
			    int annee = extraireParam(request, ANNEE_PARAM);
			    // Extraire le parametre du mois
			    int mois = extraireParam(request, MOIS_PARAM);
			    // Extraire le parametre du jour
			    int jour = extraireParam(request, JOUR_PARAM);		
			    
			    System.out.println("DEBUG: j=" + jour + ", m=" + mois + ", a=" + annee + ", aRef=" + anneesRef);
			
				// Determiner la granularite selon les valeurs des parametres
				// Utiliser la fonction determinerGranularite()
				
				int granularite = determinerGranularite(jour, mois, annee);
				
				// Si la granularite n'est pas definie (les parametres passees sont incomplets), rediriger vers le calendrier en ajoutant un parametre a l'url : error=invalidParams.
				// Cela aura pour effet qu'au chargement de la page du calendrier, la fenetre modale d'aide soit automatiquement ouverte.
				
				if (granularite == PRECISION_ND && request.getParameter("error") == null) {
			    // Rediriger vers afficherVentes.jsp avec error=invalidParams ajoute a l'URL existante
			    response.sendRedirect("afficherVentes.jsp?error=invalidParams");
			    return;
				}
				
				// Afficher la date en lettres dans l'entete
				// Utiliser la fonction dateEnLettres()
				String dateLettres = dateEnLettres(jour, mois, annee);
				
			%>
			<%= dateLettres %>
			</span></div>
		</header>
	
		<form id="setAnneesComparaison">
			<div class="form-row">
				<div class="form-group col-md-7 mx-auto">
					<label for="nbAnneesRef">Nombre d'annees de reference pour la comparaison :</label>
					<input type="number" id="nbAnneesRef" class="form-control" min="0" max="5" step="1"
						   value="<%=anneesRef %>" required>
				</div>
			</div>
		</form>
		<div id="infos" class="mb-0">
		<%
		
		//Instructions pour la preparation des donnees a des fins de visualisation.
		
		// 1- Declaration des structures de donnees pour entreposer les ventes : dates (Vecteur), montant (Vecteur) et totauxAgreges (Hashtable)
		
		// Entreposer les dates
		Vector<String> dates = new Vector<String>();
		// Entreposer les montants
		Vector<Double> montants = new Vector<Double>();
		// Entreposer les totaux agreges
		Hashtable<String, Double> totauxAgreges = new Hashtable<String, Double>();

		// 2- Extraction des donnees dans les vecteurs (Utilisation de la fonction extraireDonneesDansVecteurs())
		
		// Appeler la fonction pour extraire les donnees dans les vecteurs
		try {
		    extraireDonneesDansVecteurs(getServletContext(), CHEMIN_FICHIER_VENTES, jour, mois, annee, anneesRef, granularite, dates, montants);
		} catch (FileNotFoundException e) {
		    e.printStackTrace(); // Gerer l'exception si le fichier n'est pas trouve
		} catch (IOException e) {
		    e.printStackTrace(); // Gerer l'exception si une erreur d'entree/sortie survient
		}
				
		// 3- Agregation des donnees dans les vecteurs (Utilisation de la fonction totauxAgreges())
		
		// Appeler la fonction pour agreger les donnees
		Hashtable<String, Double> totaux = totauxAgreges(dates, montants, granularite);

		// 4- Ajout des dates manquantes pour visualisation (Utilisation de la fonction remplirVides())
		
		// Appeler la fonction pour ajouter les dates manquantes
		remplirVides(dates, jour, mois, annee, anneesRef, granularite);
		
		// 5- Tri des dates (Utilisation de la fonction trierDates())
		
		// Appeler la fonction pour trier les dates
		trierDates(dates);
		
		// 6- Preparation des donnees servant a peupler les elements du graphique (Utilisation de la fonction toChartJSData()) 
		
		// Appeler la fonction pour preparer le graphique
		// �liminer les doublons dans le vecteur des dates
		Vector<String> uniqueDates = new Vector<String>();
		for (String d : dates) {
		    if (!uniqueDates.contains(d)) {
		        uniqueDates.add(d);
		    }
		}
		String[] chartData = toChartJSData(totaux,uniqueDates, COULEUR_R, COULEUR_V, COULEUR_B);	
		
		System.out.println("CHART DATA:");
		System.out.println("Labels: " + chartData[0]);
		System.out.println("Values: " + chartData[1]);
		System.out.println("Colors: " + chartData[2]);
		
		%>
		
		</div>
		<div id="chart" class="my-0 col-lg-9 mx-auto" style="width:100%;">
			<canvas id="canvas"></canvas>
		</div>

		<h6 class="text-center pt-5 mt-0">
			Par : @Wiamei <br>
			TECH20711  - Developper un produit numerique
		</h6>
		</div>

	<script>
		<!-- la fin du chargement du document et de ses ressources-->
		window.addEventListener("load", () => {
			(() => {
				//Au clic sur le bouton "<-", proceder a une redirection vers le calendrier "index.html"
				document.getElementById("backBtn").addEventListener("click", (e) => {
					window.location.href = "index.html";
				})
				//Annuler la soumission du formulaire 
				document.getElementById("setAnneesComparaison").addEventListener("submit", (e) => {
					e.preventDefault();
				})
				
				//Au chargement de la page, envoyer automatiquement le focus au champs du formulaire
				//afin de faciliter le changement de valeur a l'aide des touches "haut" et "bas" du clavier
				const nbAnneesRef = document.getElementById("nbAnneesRef");
				nbAnneesRef.focus();
				let valNbAnneesRef;
				let aRefIndex;
				//Au changement de la valeur correspondante au nombre d'annees de reference,
				//Mettre a jour le parametre "aRef" de l'URL
				nbAnneesRef.addEventListener("change", () => {
					valNbAnneesRef = Number.parseInt(nbAnneesRef.value);
					if(Number.isInteger(valNbAnneesRef) && valNbAnneesRef >= nbAnneesRef.min && valNbAnneesRef <= nbAnneesRef.max) {
						aRefIndex = window.location.search.indexOf("&<%=ANNEES_REF_PARAM%>=");
						window.location.search =
							((aRefIndex != -1) ? (window.location.search.substring(0,aRefIndex))
											   : window.location.search)
							+ "&<%=ANNEES_REF_PARAM%>="+nbAnneesRef.value; 
					}
				});
			})();
			
			
			(() => {
				//Rcuperer le canvas
				const chart = document.getElementById('canvas').getContext('2d');
				
				//Generer le graphique
				const myChart = new Chart(chart, {
				    type: 'bar',
				    data: {
				        labels: <%= chartData[0] %>,
				        datasets: [{
				            label: 'Montant des ventes',
				            data: <%= chartData[1] %>,
				            backgroundColor: <%= chartData[2] %>,
				            borderColor: "rgba(<%= COULEUR_R %>,<%= COULEUR_V %>,<%= COULEUR_B %>,1)",
				            borderWidth: 1
				        }]
				    },
				    options: {
				        scales: {
				            yAxes: [{
				                ticks: {
				                    beginAtZero:true
				                }
				            }]
				        },
				        legend: {
				        	position: 'bottom'
				        }
				    }
				});

				
			})();
		});
	</script>
    <!-- Scripts JS pour Bootstrap (optionnel) -->
    <!-- jQuery en premier, ensuite Popper.js, Bootstrap JS et ChartJS pour terminer -->
    <script src="https://code.jquery.com/jquery-3.4.1.slim.min.js"
            integrity="sha384-J6qa4849blE2+poT4WnyKhv5vZF5SrPo0iEjwBvKU7imGFAV0wwj1yYfoRSJoZ+n"
            crossorigin="anonymous"></script>
    <!--<script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"
            integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo"
            crossorigin="anonymous"></script>  -->
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js"
            integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6"
            crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.9.3/Chart.min.js"></script>
</body>
</html>