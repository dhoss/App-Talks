#!/usr/bin/env perl

use Web::Simple 'App::Talks';

{
    package App::Talks;
    use File::Find::Rule;
    use Pod::S5;
    use Template;
    use IO::All;
    use FindBin qw/$Bin/;
    use Data::Dumper;

    sub template_out {
        my ($self, $file, $content) = @_;
        my $template = Template->new({
            INCLUDE_PATH => "templates",
            WRAPPER      => "wrapper.tt",
            POST_CHOMP   => 1,
        });
        my $output;
        $template->process($file, $content, \$output)
            || die $template->error();
        return $output;
    }

    sub find_talk_dirs {
        my $self = @_;
        my @dirs = File::Find::Rule->directory
                        ->in("talks");
        ## this seems hacky
        shift @dirs;
        return \@dirs;
    }

    sub find_pod {
        my ($self, $dir) = @_;
        File::Find::Rule->file()
                        ->name('*.pod')
                        ->in($dir);
    }
    

    sub s5 {
        my ($self, $file) = @_;
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
            $atime,$mtime,$ctime,$blksize,$blocks)
            = stat($file);
        # shamelessly yoinked from pod2s5
        my $host = `hostname`;
        my $s5 = Pod::S5->new(
            theme    => 'default',
            author   => 'Devin Austin',
            creation => $mtime,
            where    => $host,
            company  => "CodedRight.net",
            name     => $self->slide_name($file),
        );
        return $s5;
    }

    sub slide_name {
        my ($self, $file) = @_;
        # also stolen from pod2s5
        $file =~ s/\.pod$//;
        $file =~ s/[\.\_\-]/ /g;
        $file =~ s/^(.)/uc($1)/e;
        return $file;
    }

    sub build_slide_show {
        my ($self, $talk) = @_;
        my $file = $self->find_pod($talk);
        my $s5 = $self->s5($file);
        return $s5->process;
    }

    sub dispatch_request {
        
        sub(GET) {
            my $self = shift;
            [ 200, [ 'Content-Type', 'text/html' ], 
              [ 
                $self->template_out('index.tt', { directories => $self->find_talk_dirs() } ) 
              ] 
            ]
        }


    };
}

App::Talks->run_if_script();
