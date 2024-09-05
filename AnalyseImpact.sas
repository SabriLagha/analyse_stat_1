/* Importer le fichier Excel */
proc import datafile="/home/u59452063/sasuser.v94/Questionnaire sur l'utilisation du téléphone et le temps d'écran (réponses).xlsx" out=Données dbms=xlsx replace;
  sheet="Réponses au formulaire 1";
  getnames=yes; /* Spécifie que la première ligne contient les noms de variables */
run;

/* Afficher les noms des variables dans le jeu de données */
proc contents data=Données out=Variables noprint;
run;

/* Afficher les noms des variables */
proc print data=Variables noobs;
   var varnum name;
   label name="Nom de la variable";
run;


/* Renommer les variables pour faciliter leur utilisation */
data Reponses;
  set Données;
  rename 
    "Avez-vous déjà essayé de réd"n = reduire
    "Combien de temps en moyenne pass"n = temps
    "Pensez-vous que votre utilisatio"n = nefaste
    "Pratiquez vous une activité spo"n = sport
    "Quel est votre genre ?"n = sexe
    "Quel est votre statut actuel ?"n = metier
    "Quel est votre statut relationne"n = relation
    "Quel est votre âge ?"n = age
    "Quelles activités effectuez-vou"n = utilisation_principale
    "Si oui, combien de fois par sema"n = nb_sport
    'Si vous avez répondu "Oui" à l'n= methode_reduc
    'Si vous avez répondu "Oui" à_1'n= motiv_reduc
    "À quel moment de la journée ut"n= moment_util
    "À quelle fréquence utilisez-vo"n = freq_util
    "Êtes-vous conscient des effets"n = conscience
    ;
  drop Horodateur;
run;


/* Afficher les noms des variables dans le jeu de données */
proc contents data=Reponses out=Variables noprint;
run;

proc freq data=Reponses;
   tables metier / nocum;
run;

/* Regrouper les modalités similaires de la variable "metier" */
data Reponses;
   set Reponses;


   /* Regrouper les modalités "Sans emploi" et "Sans profession" en "Sans emploi/profession" */
   if metier = "Sans emploi" or metier = "Sans profession" or metier = "Rien" or metier = "Demandeur d'emploi" or metier = "Retraités" or metier ="." then metier = "Sans emploi";
   if metier = "Auto entrepreneur" or metier = "Auto-entrepreneuse" or metier = "autoentrepreneur" or metier = "Entrepreneur" or metier = "Chef d’entreprise" or metier="Indépendant" then metier = "Entrepreneur";
   if metier = "Alternant" or metier = "Stagiaire" or metier = "étudiant + employé à temps partiel" then metier = "Etudiant";
   if metier = "Mère au foyer" or metier = "Maman au foyer" or metier = "Foyer mère" or metier = "Femme au foyer" or metier = "Au foyer" then metier = "Mère au foyer";
  
   if relation = "." then relation = "Célibataire";
   if relation = "en couple mais c’est compliqué" then relation = "En couple";
run;

proc freq data=Reponses_modifie;
   tables metier / nocum;
run;

data Reponses_modifie;
   set Reponses;
   
   format nb_sport 3. freq_util 3. temps 3.;
   /* Encoder la variable nb_sport */
   if nb_sport = "1 à 2 fois par semaine" then nb_sport_num = 2;
   else if nb_sport = "3 à 4 fois par semaine" then nb_sport_num = 4;
   else if nb_sport = "5 à 6 fois par semaine" then nb_sport_num = 6;
   else nb_sport_num = 0; 

   if freq_util = "1 à 3 heures" then freq_util_num = 2;
   else if freq_util = "3 à 5 heures" then freq_util_num = 4;
   else if freq_util = "Moins d'une heure" then freq_util_num = 0.5;
   else if freq_util = "Plus de 5 heures" then freq_util_num = 6;
   else freq_util_num = 0; 
   
   if temps = "Moins de 30 minutes" then temps_num = 0;
   else if temps = "Entre 30 minutes et 1 heure" then temps_num = 1;
   else if temps = "Entre 1 heure et 2 heures" then temps_num = 2;
   else if temps = "Plus de 2 heures" then temps_num = 3;
  
   drop nb_sport freq_util temps; /* Supprimer l'ancienne variable nb_sport */
   rename nb_sport_num = nb_sport freq_util_num = freq_util temps_num = temps; /* Renommer la nouvelle variable nb_sport_num en nb_sport */
run;

ods rtf file="/home/u59452063/DARM/rapport.doc" style=HtmlBlue;

PROC FREQ DATA=Reponses_modifie;
   TABLES sport * _CHARACTER_ / OUT=Description;
RUN;

PROC PRINT DATA=Description;
RUN;


proc means data=Reponses_modifie n mean std median min max lclm uclm maxdec=3;
	var nb_sport freq_util temps;
run;

proc univariate data=Reponses_modifie normal plot;
   var nb_sport;
   histogram / normal;
run;

proc univariate data=Reponses_modifie normal plot;
   var freq_util;
   histogram / normal;
run;

proc univariate data=Reponses_modifie normal plot;
   var temps;
   histogram / normal;
run;


proc glm data=Reponses_modifie;
class nb_sport;
model temps=nb_sport;
means nb_sport/hovtest=Levene;
run;

proc glm data=Reponses_modifie;
class nb_sport;
model freq_util=nb_sport;
means nb_sport/hovtest=Levene;
run;

proc freq data=reponses_modifie;
tables temps /chisq;
run;

/* Tirage proportionnel */

PROC SURVEYSELECT DATA=reponses_modifie NOPRINT
 OUT=Tirage_proportionnel
 SEED=31169 /*Graine pour figer les résultats*/
 N=50 /*Sélection de 150 valeurs*/
 METHOD=PPS_WR /*Tirage proportionnel avec remise*/
 OUTHITS /*Afficher toutes les lignes*/;
 SIZE freq_util; 
RUN;

/* Tirage Aléatoire */
PROC SURVEYSELECT DATA=reponses_modifie NOPRINT
 OUT=TIRAGE_aléatoire
 SEED=31169 /*Graine pour figer les résultats*/
 N=100 /*Sélection de 100 valeurs*/
 METHOD=URS /*Tirage avec remise*/
 OUTHITS /*Afficher toutes les lignes*/;
RUN;


/* Boostrap */

%MACRO SIMULATION(N=,SEED=);
	/* Tirage aléatoire */
	PROC SORT DATA=Reponses_modifie OUT=Reponses_S;
	BY sport;
	RUN;

	PROC SURVEYSELECT DATA=Reponses_S NOPRINT
		OUT=Base_Reponses
		SEED=&SEED /* Graine pour figer les résultats */
		N=&N /* Sélection de N personnes par strate */
		REPS=100 /* Réaliser 100 tirages */
		METHOD=URS /* Tirage avec remise */
		OUTHITS /* Afficher toutes les lignes */;
	STRATA sport /* Tirage avec strate sur le sport */;
	RUN;

	/* Calcul de la différence des moyennes */
	PROC SORT DATA=Base_Reponses;
	BY replicate sport;
	RUN;

	ODS OUTPUT Statistics=Statistics_&N. (WHERE=(CLASS="Diff (1-2)" AND METHOD="Pooled"));

	PROC TTEST DATA=Base_Reponses;
	CLASS sport;
	VAR temps;
	BY replicate;
	RUN;

	DATA Statistics_&N.;
	SET Statistics_&N.;
	N=&N.;
	RUN;

	/* Suppression des tables créées dans la macro */
	PROC DATASETS LIB=WORK NOLIST;
	DELETE Base_Reponses Reponses_S;
	RUN;
	QUIT;
%MEND SIMULATION;

/* diminution échantillon */
%SIMULATION(N=10, SEED=10);

/* Augmentation échantillon */
%SIMULATION(N=1000,SEED=70);

DATA BASE_ALL;
SET STATISTICS_10
	STATISTICS_1000;
RUN; 

PROC UNIVARIATE DATA=BASE_ALL;
CLASS N;
VAR MEAN;
OUTPUT OUT=TABLE_PERCENTILE PCTLPTS=2.5 50 97.5 PCTLPRE=P;
RUN;

/*Regroupement des observations et percentiles*/
PROC SORT DATA=BASE_ALL;
BY N;
RUN;
DATA BASE_PLOT;
MERGE BASE_ALL TABLE_PERCENTILE;
BY N;


ods rtf close;