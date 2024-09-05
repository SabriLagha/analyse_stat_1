/* Importer le fichier Excel */
proc import datafile="/home/u59452078/M2DARM/Analyse d'impact/Sondage.xlsx" out=Reponses dbms=xlsx replace;
  sheet="Réponses au formulaire 1";
  getnames=yes; /* Spécifie que la première ligne contient les noms de variables */
run;

/* Renommer les variables pour faciliter leur utilisation */
data Reponses;
  set Reponses;
  rename 
    "Quel est votre genre ?"n = sexe
    "Quel âge avez vous ? "n = age
    "Avez-vous déjà passé l'examen"n = passage_code
    "Combien de fois l'avez vous pass"n = nb_code
    "Comment jugez vous la difficult"n = diff_code
    "Avez-vous fait de la conduite ac"n = conduite_acc
    "Avez vous déjà passé l'examen"n = passage_permis
    "Combien de fois l'avez vous pa_1"n = nb_permis
    "Comment jugez vous la difficul_1"n = diff_permis
    "Avez vous déjà réussi l'exame"n = reussite_permis
    "L'avez vous actuellement"n=possession_permis
    "Depuis combien de temps l'avez-v"n=anciennete_permis
    "Combien de points avez-vous ?"n=points
    "Etes-vous véhiculé ?"n = vehicule
    "A quoi vous sert le permis ?"n = utilite_permis
    "Avez-vous déjà perdu le permis"n = perte_permis
    "Où habitez vous ?"n = lieu_vie;
run;


/* Activer l'extension ODS pour la sortie au format Word */
ods rtf file="/home/u59452078/M2DARM/Analyse d'impact/rapport.doc" style=HtmlBlue;

/* Description globale */
proc contents data=Reponses out=VariableInfo(keep=name type length label);
run;

/* Description globale */
proc means data=Reponses n mean std median min max lclm uclm maxdec=3;
	var nb_code diff_code nb_permis diff_permis points;
run;

/*visualiser l'âge des sondés*/
proc sgplot data=Reponses;
  hbar age/ discreteoffset=0.5;
run;


/*Lieu de vie des sondés*/
proc sgplot data=Reponses;
  hbar lieu_vie/ discreteoffset=0.5;
run;

proc sgplot data=Reponses;
  vbar diff_permis / datalabel;
run;


/* test de comparaison sur la variable diff_permis (note sur la difficulté de l'examen du permis de conduire entre 1 et 5 obtenue par échelle linéaire)
 On va tester dans un premier temps la normalité des données*/
proc univariate data=Reponses normal plot;
var diff_permis;
run;
/*Les p-values des tests de normalité sont toutes inférieures aux seuils de signification couramment utilisés (0,05). Cela suggère que les données ne suivent pas une distribution normale.*/
/* Comme les données ne suivent pas une loi normal nous allons effectué un test de Levene*/

/*Nous faisons un test de Levene*/
proc glm data=Reponses;
  class diff_permis;
  /*nous choisissons la variable dépendante nb_permis(nombre de fois que la personne a passé le permis)*/
  model nb_permis = diff_permis;
  means diff_permis / hovtest=Levene;
/*Ce code nous permet de savoir s'il y a une différence significative entre les modalités de diff_permis en ce qui concerne nb_permis*/
/*ANOVA : la p-value = 0.0121 < 0.05 nous pouvons donc affirmer qu'il y a une différence significative entre au moins deux modalités de diff_permis en ce qui concerne nb_permis*/
/*LEVENE : p-value=0.08662 > 0.05 nous ne pouvons pas rejeter l'hypothèse nulle d'homogénéité de variance */
/*Il n'y a pas de difference significative entre les modalité de diff_permis par rapport à nb_permis*/

/*test du chi-carré*/
proc freq data=reponses;
tables diff_permis /chisq;
run;
/*le test Khi-2 a une p-value de 0.0005 <0.005 ce qui suggère une différence significative entre les modalités de diff_permis*/



/*BOOTSRAP*/
/*TEST MACRO 1*/
/* Étape 1 : Définir la macro */
%macro tirage_proportionnel(data, variable, output);
  proc sort data=Reponses;
    by diff_permis;
  run;
  /* Obtenir la taille de l'échantillon à augmenter */
  proc sql noprint;
    select count(distinct &variable)
    into :N
    from &data;
  quit;

  /* Tirage aléatoire proportionnel */
  proc surveyselect data=&data out=&output
    method=urs /* Tirage aléatoire avec remise */
    sampsize=&N /* Taille de l'échantillon à augmenter */
    seed=12345; /* Graine pour la reproductibilité */

  /* Spécifier la variable de strate pour le tirage proportionnel */
  strata &variable;

  run;

  /* Effectuer les tests statistiques sur la population augmentée */
  proc freq data=&output;
    tables &variable /chisq;
  run;
%mend;

/* Étape 2 : Appeler la macro avec les paramètres appropriés */
%tirage_proportionnel(data=Reponses, variable=diff_permis, output=Population_Proportionnel);


/*TEST MACRO 2*/
/* Étape 1 : Définir la macro */
%macro tirage_proportionnel2(data, variable, output);
  /* Définir la taille de l'échantillon à augmenter */
  %let N = 1000;
  proc sort data=Reponses;
    by diff_permis;
  run;
  /* Tirage aléatoire proportionnel */
  proc surveyselect data=&data out=&output
    method=urs /* Tirage aléatoire avec remise */
    sampsize=1000 /* Taille de l'échantillon à augmenter */
    seed=12345; /* Graine pour la reproductibilité */

  /* Spécifier la variable de strate pour le tirage proportionnel */
  strata &variable;

  run;

  /* Effectuer les tests statistiques sur la population augmentée */
  proc freq data=&output;
    tables &variable /chisq;
  run;
%mend;

/* Étape 2 : Appeler la macro avec les paramètres appropriés */
%tirage_proportionnel2(data=Reponses, variable=diff_permis, output=Population_Proportionnel);

/* Désactiver l'extension ODS */
ods rtf close;



