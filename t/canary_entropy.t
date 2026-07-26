use strict;
use warnings;
use Test::More tests => 3;
use lib 'lib';

my $script = 'lava_loop_primer.pl';
my $fasta = 't/synthetic_entropy.fasta';
my $output = 't/canary_entropy_out.txt';

# Exécuter avec un seuil de 1.5 pour exclure la zone centrale très variable
my $cmd = "perl $script --alignment_fasta $fasta --output_file $output --entropy_threshold 1.5 --primer3_executable /opt/homebrew/bin/primer3_core";
my $res = `$cmd 2>&1`;

# On vérifie qu'aucune amorce n'a été trouvée (car la zone est exclue et les flancs sont trop petits pour tout caser, ou bien l'exclusion bloque Primer3)
ok($res =~ /AUCUN OLIGO TROUVÉ/, "LAVA ne trouve aucune amorce quand la zone centrale est exclue");

# Vérifier que le diagnostic mentionne la zone exclue
ok($res =~ /Régions exclues par entropie/, "Le diagnostic affiche les zones exclues par entropie");

# Exécuter avec un seuil de 5.0 (très haut, rien ne sera exclu)
$cmd = "perl $script --alignment_fasta $fasta --output_file $output --entropy_threshold 5.0 --primer3_executable /opt/homebrew/bin/primer3_core";
$res = `$cmd 2>&1`;

ok($res !~ /AUCUN OLIGO TROUVÉ/, "LAVA trouve des amorces quand le seuil d'entropie est assez haut pour ne rien exclure");
