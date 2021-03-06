/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkSerafinReader.h,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/

////// Reader for files generated by The  TELEMAC modelling system \\\\\
// Module developped by herve ozdoba - Sept 2008 ( herve-externe.ozdoba at edf.fr / herve at ozdoba.fr )
// Please address all comments to Regina Nebauer ( regina.nebauer at edf.fr )
// >>> Test version

#ifndef __vtkSerafinReader_h__
#define __vtkSerafinReader_h__

/** -- Inclusions issues de la bibliothèque standard du C++ -- */

#include <fstream>
#include <string>
#include <cstdio>
#include <iostream>
#include <cstring>

using namespace std;

/** -- Inclusion des entêtes de la bibliothèque vtk -- **/

#include "vtkUnstructuredGridAlgorithm.h"

#include "vtkStringArray.h"


#include "stdSerafinReader.h"

#include "vtkIntArray.h"
#include "vtkFloatArray.h"
#include "vtkStdString.h"
#include "vtkDoubleArray.h"
#include "vtkIntArray.h"
#include "vtkCellArray.h"


/** ********************************************************************************************* **/
/** -- Definition de la classe de lecture des fichiers externes au format Serafin pour Telemac -- **/
/** ********************************************************************************************* **/

class VTK_IO_EXPORT vtkSerafinReader  : public vtkUnstructuredGridAlgorithm
{
public:

	static vtkSerafinReader *New();

	vtkTypeRevisionMacro(vtkSerafinReader,vtkUnstructuredGridAlgorithm);
	void PrintSelf(ostream& os, vtkIndent indent);

	vtkSetStringMacro(FileName);
	vtkGetStringMacro(FileName);

	vtkSetMacro(TimeStep, int);
	vtkGetMacro(TimeStep, int);

	int IsValidFile();

protected:
	
	// Impl?mentation du constructeur associ? ? la classe
	vtkSerafinReader();

	// Impl?mentation du descructeur
	~vtkSerafinReader();

	int RequestInformation	(vtkInformation *, vtkInformationVector **, vtkInformationVector *);
	int RequestData		(vtkInformation *, vtkInformationVector **, vtkInformationVector *);

	// Cette fonction permet de lire les donn?es d'un fichier selon qu'elles soient 'inscrites' au niveau des ?l?ments ou des points . 
	// De plus , elle appelle la m?thode de lecture de la g?om?trie du maillage .
	void ReadFile		 (vtkUnstructuredGrid *output, int time);

	// Lecture de la g?om?trie du maillage
	void ReadGeometry	 (vtkUnstructuredGrid *output, int time);

	// Lecture des donn?es de la simulation au niveau des noeuds et des cellules.
	void ReadData	 (vtkUnstructuredGrid *output, int time);

	char 	 *FileName;	 // Nom du fichier ouvert par le logiciel Paraview
	ifstream *FileStream;// Flux de lecture du fichier
	
	int TimeStep;

	stdSerafinReader* Reader; /** /!\ Instance de lecture du fichier Serafin **/

private:
	vtkSerafinReader(const vtkSerafinReader&);	// Pas implémenté
	void operator=(const vtkSerafinReader&);  	// Pas implémenté

}; /* class_vtkSerafinReader */

#endif

