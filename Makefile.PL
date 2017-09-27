sub readme_from {}; sub auto_include_deps {}; sub author_tests {}; sub auto_set_repository {};
use inc::Module::Install;
name 'Test2-Log-Log4perl';
all_from 'lib/Test2/Log/Log4perl.pm';
readme_from 'lib/Test2/Log/Log4perl.pm';
build_requires 'Test::More';
requires 'Log::Log4perl';
requires 'Test::Builder::Tester';
requires 'Test::Exception';
author_tests('xt');
auto_set_repository;
WriteAll;

