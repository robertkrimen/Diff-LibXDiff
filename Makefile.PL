# From ExtUtils::MakeMaker 6.48 and DBI 1.43
use 5.006;
use strict;
use ExtUtils::MakeMaker;
use Config;

# Some dependencies need to be more aggressive on Windows
sub WINLIKE () {
	return 1 if $^O eq 'MSWin32';
	return 1 if $^O eq 'cygwin';
	return '';
}

# Make setting optional MakeMaker parameters more readable
sub OPTIONAL {
	return () unless $ExtUtils::MakeMaker::VERSION ge shift;
	return @_;
}

my $force_local = 1;

my (@CC_LIBS, @CC_INC, @CC_DEFINE);

push @CC_LIBS, '-lxdiff';

#my @CC_LIBS = ();
#if ( $sqlite_lib ) {
#    push @CC_LIBS, "-L$sqlite_lib";
#}
#unless ( $force_local ) {
#    push @CC_LIBS, '-lsqlite3';
#}

#my @CC_INC = (
#    '-I.',
#    '-I$(DBI_INSTARCH_DIR)',
#);
#if ( $sqlite_inc ) {
#    push @CC_INC, "-I$sqlite_inc";
#}

#my @CC_DEFINE = (
#    '-DSQLITE_CORE',
#    '-DSQLITE_ENABLE_FTS3',
#    '-DSQLITE_ENABLE_COLUMN_METADATA',
#    '-DNDEBUG=1',
#    "-DSQLITE_PTR_SZ=$Config{ptrsize}"
#);
#if ( $Config{d_usleep} || $Config{osname} =~ m/linux/ ) {
#    push @CC_DEFINE, '-DHAVE_USLEEP=1';
#}
#unless ( $Config{usethreads} ) {
#    push @CC_DEFINE, '-DTHREADSAFE=0';
#}
#if ($^O eq 'hpux' and $Config{osvers} <= 10.20) {
#    push @CC_DEFINE, '-DSQLITE_OMIT_LOAD_EXTENSION';
#}

my @CC_OPTIONS = (
	INC          => join( ' ', @CC_INC    ),
	DEFINE       => join( ' ', @CC_DEFINE ),
	( @CC_LIBS ? (
		LIBS => join( ' ', @CC_LIBS )
	) : () ),
);

WriteMakefile(
	NAME             => 'Diff::LibXDiff',
	ABSTRACT         => 'Durp!',
	VERSION_FROM     => 'lib/Diff/LibXDiff.pm',
	PREREQ_PM        => {
		'Test::More'       => '0.42',
	},
	OPTIONAL( '6.48',
		MIN_PERL_VERSION => '5.006',
	),
	OPTIONAL( '6.31',
		LICENSE => 'perl',	
	),
	OPTIONAL( '6.11',
#		AUTHOR  => 'Adam Kennedy <adamk@cpan.org>', # Release manager (can this be an array?)
		AUTHOR  => 'Durp!',
	),
	OPTIONAL( '6.46',
		META_MERGE => {
#            configure_requires => {
#                'ExtUtils::MakeMaker' => '6.48',
#                'File::Spec'          => '0.82', # This is not allowed to be computed
#                'DBI'                 => $DBI_required,
#            },
#            build_requires => {
#                'File::Spec'          => (WINLIKE ? '3.27' : '0.82'),
#                'Test::More'          => '0.42',
#                # 'Test::NoWarnings'    => '0.081', # Bundled in /inc
#            },
#            resources => {
#                license     => 'http://dev.perl.org/licenses/',
#                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=DBD-SQLite',
#                repository  => 'http://svn.ali.as/cpan/trunk/DBD-SQLite',
#                MailingList => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/dbd-sqlite',
#            },
			no_index => {
				directory => [ qw{
					t inc util
				} ],
			}
		},
	),
	OBJECT => (
		'$(O_FILES)'
	),
	OPTIMIZE         => '-O2',
	clean            => {
#        FILES => 'SQLite.xsi config.h tv.log',
	},
	PL_FILES         => {},
	EXE_FILES        => [],

	@CC_OPTIONS,
);

#package MY;

#use Config;

#sub postamble {
#    require DBI;
#    require DBI::DBD;
#    eval {
#        DBI::DBD::dbd_postamble(@_)
#    };
#}

#sub libscan {
#    my ($self, $path) = @_;
#    return if $path =~ /\.pl$/;
#    ($path =~ m/\~$/) ? undef : $path;
#}

#sub test_via_harness {
#    my ($self, $perl, $tests) = @_;
#    if ( $^O eq 'hpux' and $Config{osvers} <= 10.20 ) {
#        return qq{\tPERL_DL_NONLAZY=0 $perl "-MExtUtils::Command::MM" }
#             . qq{"-e" "test_harness(\$(TEST_VERBOSE), '\$(INST_LIB)', '\$(INST_ARCHLIB)')" $tests\n};
#    } else {
#        $self->SUPER::test_via_harness($perl, $tests);
#    }
#}

#sub test_via_script {
#    my ($self, $perl, $script) = @_;
#    if ( $^O eq 'hpux' and $Config{osvers} <= 10.20 ) {
#        return qq{\tPERL_DL_NONLAZY=0 $perl "-I\$(INST_LIB)" "-I\$(INST_ARCHLIB)" $script\n};
#    } else {
#        $self->SUPER::test_via_script($perl, $script);
#    }
#}
