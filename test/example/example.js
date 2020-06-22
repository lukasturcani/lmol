import { molecule1 } from './molecule1';
import { molecule2 } from './molecule2';


import * as md from '../../output/MolDraw';


// Live preview molecules.
const maybeMolecule1 = md.maybeParseV3000(molecule1);
if (md.isLeft(maybeMolecule1))
{
    console.log('Issue with preview molecule 1.');
    console.log(md.fromLeft()(maybeMolecule1));
}
else
{
    md.drawMol({
        backgroundColor: 0xFFFFFF,
        containerId: 'container1',
    })(md.fromRight()(maybeMolecule1));
}

const maybeMolecule2 = md.maybeParseV3000(molecule2);
if (md.isLeft(maybeMolecule2))
{
    console.log('Issue with preview molecule 2.');
    console.log(md.fromLeft()(maybeMolecule2));
}
else
{
    md.drawMol({
        backgroundColor: 0xFFFFFF,
        containerId: 'container2',
    })(md.fromRight()(maybeMolecule2));
}



// readme.rst example 1.

// You can load molecules by parsing them from V3000 MDL .mol
// file contents.
const eg1 = md.maybeParseV3000(`
  0  0  0  0  0  0  0  0  0  0999 V3000
M  V30 BEGIN CTAB
M  V30 COUNTS 4 3 0 0 0
M  V30 BEGIN ATOM
M  V30 1 Br -0.0328 1.8852 0.0012 0
M  V30 2 C 0.0054 -0.0185 -0.0002 0 CHG=1
M  V30 3 H 1.6829 -0.9147 -0.0823 0
M  V30 4 H -1.6555 -0.9520 0.0814 0
M  V30 END ATOM
M  V30 BEGIN BOND
M  V30 1 1 1 2
M  V30 2 1 2 3
M  V30 3 1 2 4
M  V30 END BOND
M  V30 END CTAB
M  END
`);

// if isLeft(eg1) returns True - it means parsing the molecule
// failed, allowing you to gracefully handle the error.
if (md.isLeft(eg1))
{
    console.log('There was an issue with your V3000 file content.');
    // You can use md.fromLeft()(eg1) to extract the error message.
    console.log(md.fromLeft()(eg1));
}
else
{
    // If the parse was successful, you can use
    // md.fromRight()(eg1) to extract the molecule.
    const molecule = md.fromRight()(eg1);
    md.drawMol({
        backgroundColor: 0xFFFFFF,
        // Id of the div, in which the molecule should be rendered.
        containerId: 'container3'
    })(molecule);


    // readme.rst example 2.

    // If you want to customize the drawing you can add an options
    // object.

    md.drawMolWithOptions({
        // atomSize is a function, which takes a molDraw.GeometryAtom
        // instance and returns the desired size (before scaling).
        atomSize: atom => {
            // Make the atom with an id of 1 really big.
            if (md.id(atom) === 1)
            {
                return 3;
            }
            // Make hydrogen atoms really small.
            if (md.show(md.chemicalSymbol(atom)) === 'H')
            {
                return 0.15;
            }
            // Use the default element sizes for everything else.
            return md.size(md.chemicalSymbol(atom));
        },
        // atomColor is a function, which takes a molDraw.GeometryAtom
        // instance and returns the desired color for that atom.
        atomColor: atom => {
            // Make the atom with id of 8 red.
            if (md.id(atom) === 3)
            {
                return 0xFF0000;
            }
            // Make carbon atoms purple.
            if (md.show(md.chemicalSymbol(atom)) === 'C')
            {
                return 0x800080;
            }
            // Use the default element colors for everything else.
            return md.color(md.chemicalSymbol(atom));
        },
        atomScale: 0.5,
        atomWidthSegments: 8,
        atomHeightSegments: 7,
        bondRadialSegments: 10,
        bondHeightSegments: 1
    })({
        backgroundColor: 0xFFFFFF,
        containerId: 'container4'
    })(molecule);
}

