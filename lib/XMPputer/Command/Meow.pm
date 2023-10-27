package XMPputer::Command::Meow;

##############################################################################
#   XMPputer - very simple XMPP bot                                          #
#   Copyright (C) 2023 Yair Yarom                                            #
#                                                                            #
#   This program is free software: you can redistribute it and/or modify     #
#   it under the terms of the GNU General Public License as published by     #
#   the Free Software Foundation, either version 3 of the License, or        #
#   (at your option) any later version.                                      #
#                                                                            #
#   This program is distributed in the hope that it will be useful,          #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of           #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
#   GNU General Public License for more details.                             #
#                                                                            #
#   You should have received a copy of the GNU General Public License        #
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.   #
##############################################################################

use warnings;
use strict;

use utf8;

use base "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*meow\s*$/i) {
        return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*meow\s*$/i) {
        my @cats = (
                    #'咥', # 0x54a5: CJK UNIFIED IDEOGRAPH-54A5, sound of a cat; bite; laugh. (probably not cat specifically)
                    '咪', # 0x54aa: CJK UNIFIED IDEOGRAPH-54AA, sound of cat, cat's meow; meter; (Cant.) don't!
                    '喵', # 0x55b5: CJK UNIFIED IDEOGRAPH-55B5, the mew of the cat
                    #'猫', # 0x732b: CJK UNIFIED IDEOGRAPH-732B, cat
                    #'貓', # 0x8c93: CJK UNIFIED IDEOGRAPH-8C93, cat
                    #'ꊶ',  # 0xa2b6: YI SYLLABLE CAT
                    #'챁', # 0xcc41: HANGUL SYLLABLE CAT
                    #'𐇬', # 0x101ec: PHAISTOS DISC SIGN CAT
                    '🐈', # 0x1f408: CAT
                    '🐱', # 0x1f431: CAT FACE
                    '😸', # 0x1f638: GRINNING CAT FACE WITH SMILING EYES
                    '😹', # 0x1f639: CAT FACE WITH TEARS OF JOY
                    '😺', # 0x1f63a: SMILING CAT FACE WITH OPEN MOUTH
                    '😻', # 0x1f63b: SMILING CAT FACE WITH HEART-SHAPED EYES
                    #'😼', # 0x1f63c: CAT FACE WITH WRY SMILE
                    '😽', # 0x1f63d: KISSING CAT FACE WITH CLOSED EYES
                    #'😾', # 0x1f63e: POUTING CAT FACE
                    #'😿', # 0x1f63f: CRYING CAT FACE
                    #'🙀', # 0x1f640: WEARY CAT FACE
                    'prrr',
                   );
        return $cats[rand(@cats)];
    }

    return "Bad meow command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return 1;
    #return $params->acl->allow("meow", $params);
}

sub name {
    return "meow";
}

sub help {
    my $self = shift;
    my $params = shift;

    if ($self->allow($params)) {
        return "meow";
    }
    return "";
}

1;
