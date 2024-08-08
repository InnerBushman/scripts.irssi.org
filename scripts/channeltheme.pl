use strict;
use warnings;
use Irssi qw(command_bind signal_add);
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
    authors     => 'Wojciech Nycz',
    contact     => 'inner.bushman@gmail.com',
    name        => 'Channel Theme switcher',
    description => 'This script allows ' .
                   'you to swicth theme ' .
                   'on a per channel basis.',
    license     => 'GPLv2',
);

my $preprint = '%9Channel Theme%n> ';

# Define a setting for channel-theme pairs
Irssi::settings_add_str('channel_theme', 'channel_theme_pairs', '');

# Function to parse the settings
sub parse_settings {
    my $pairs_str = Irssi::settings_get_str('channel_theme_pairs');
    
    my @pairs = split /;/, $pairs_str;
    
    my %channel_themes;
    foreach my $pair (@pairs) {
        my ($channel, $theme) = split /=/, $pair;
        if (defined $channel && defined $theme) {
            $channel_themes{'#' . $channel} = $theme;
        }
    }
    
    return %channel_themes;
}

# Function to save the settings
sub save_settings {
    my %channel_themes = @_;

    my @pairs;
    foreach my $channel (keys %channel_themes) {
        my $clean_channel = $channel;
        $clean_channel =~ s/^#//;  # Remove the leading # for storage
        push @pairs, "$clean_channel=$channel_themes{$channel}";
    }

    my $new_pairs_str = join(';', @pairs);
    Irssi::settings_set_str('channel_theme_pairs', $new_pairs_str);
}

# Command to add a channel-theme pair
sub cmd_add {
    my ($data, $server, $witem) = @_;
    my ($channel, $theme) = split /\s+/, $data, 2;

    # Check if both channel and theme are provided
    if (!$channel || !$theme) {
        Irssi::print("Usage: /channeltheme add <channel> <theme>");
        return;
    }

    # Ensure the channel name starts with #
    $channel =~ s/^#?/#/;

    my %channel_themes = parse_settings();
    $channel_themes{$channel} = $theme;
    save_settings(%channel_themes);

    Irssi::print("Added channel-theme pair: $channel = $theme");
}


# Command to remove a channel-theme pair
sub cmd_remove {
    my ($data, $server, $witem) = @_;
    my $channel = $data;

    # Check if the channel is provided
    if (!$channel) {
        Irssi::print("Usage: /channeltheme remove <channel>");
        return;
    }

    # Ensure the channel name starts with #
    $channel =~ s/^#?/#/;

    my %channel_themes = parse_settings();

    # Check if the channel exists in the settings
    if (exists $channel_themes{$channel}) {
        delete $channel_themes{$channel};
        save_settings(%channel_themes);
        Irssi::print("Removed channel-theme pair for channel: $channel");
    } else {
        Irssi::print("Channel $channel not found in the list.");
    }
}


sub cmd_list {
    my $pairs_str = Irssi::settings_get_str('channel_theme_pairs');
    
    my @pairs = split /;/, $pairs_str;

    Irssi::print("Channel-Theme Pairs:");
    foreach my $pair (@pairs) {
        my ($channel, $theme) = split /=/, $pair;
        if (defined $channel && defined $theme) {
            Irssi::print("Channel: #$channel -> Theme: $theme");
        }
    }
}

# Display help message
sub cmd_help {
    my $help = $IRSSI{name} . " " . $VERSION . "
    
This script allows to automatically switch themes based on the channel you're currently viewing.

Usage:
/channeltheme <subcommand> [parameters]

Subcommands:
    ADD <channel> <theme>   - Associates a theme with a channel.
    REMOVE <channel>        - Removes the theme association for a channel. 
    LIST                    - Lists all the channel-theme pairs currently configured.
    HELP                    - Displays this help message.

The script automatically applies the configured theme when you switch to a channel that has an associated theme.
If no theme is associated with a channel, the default theme will be applied.

Example configuration:
    /channeltheme add foo theme1.theme
    /channeltheme add #bar theme2.theme
    /channeltheme list
    /channeltheme remove foo

For persistent configuration, the channel-theme pairs are stored in the Irssi setting
";
    
    Irssi::print($help, MSGLEVEL_CLIENTCRAP);
}

# 
sub cmd_test {
#                Irssi::settings_set_str('theme', 'fuelrats.theme');
                Irssi::command("^SET theme fuelrats.theme");
}

sub channel_theme_handler {
    my ($data, $server, $witem) = @_;

    # Split the data into command and arguments
    my ($subcommand, $args) = split(/\s+/, $data, 2);

    if ($subcommand eq 'add') {
        cmd_add($args);
    } elsif ($subcommand eq 'remove') {
        cmd_remove($args);
    } elsif ($subcommand eq 'list') {
        cmd_list($args);
    } elsif ($subcommand eq 'help') {
        cmd_help($args);
    } elsif ($subcommand eq 'test') {
        cmd_test($args);
    } else {
        Irssi::print("Unknown subcommand: $subcommand");
        Irssi::print("Usage: /channeltheme add <channel> <theme>");
    }
}

sub cmd_window_change {
    my ($new_window, $old_window) = @_;

    my %channel_themes = parse_settings();

    # Check if the new window has a window item
    if (my $witem = $new_window->{"active"}) {
        # Check if the window item is a channel
        if ($witem->{type} eq "CHANNEL") {
            my $channel_name = $witem->{name};

            # Check if the channel is in the configured list
            if (exists $channel_themes{$channel_name}) {
                my $theme_file = $channel_themes{$channel_name};

                # Apply the theme for the specific channel
#                Irssi::settings_set_str('theme', $theme_file);
                Irssi::command("^SET theme $theme_file");
            } else {
                # Apply the default theme if the channel is not in the list
#                Irssi::settings_set_str('theme', 'default.theme');
                Irssi::command("^SET theme default.theme");
            }
        } else {
            # Apply the default theme if the window item is not a channel
#            Irssi::settings_set_str('theme', 'default.theme');
            Irssi::command("^SET theme default.theme");
        }
    } else {
        # Apply the default theme if there is no active window item
#        Irssi::settings_set_str('theme', 'default.theme');
        Irssi::command("^SET theme default.theme");
    }
}


######################
### initialisation ###
######################
# Command handler for script
Irssi::command_bind('channeltheme', \&channel_theme_handler);

# Signal handler for window change
Irssi::signal_add 'window changed' =>\&cmd_window_change;
 
print CLIENTCRAP $preprint.$IRSSI{name}.' '.$VERSION.' loaded: type /channeltheme help for help';

