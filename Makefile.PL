use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'         => 'Algorithm::MarkovChain',
              'VERSION_FROM' => 'MarkovChain.pm', # finds $VERSION
              'dist' => {
                         COMPRESS=>'gzip -9f',
                         SUFFIX=>'gz',
                         DIST_DEFAULT => 'tardist'
                        },
              $] >= 5.005 ? ('AUTHOR'   => 'Richard Clamp <richardc@unixbeard.net>',
                             'ABSTRACT' => 'Markov Chain implementation',
                            ) : ()

             );
