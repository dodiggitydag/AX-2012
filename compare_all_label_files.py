import csv
import os
import re

##############
# Parameters #
##############

# Three-letter label prefix
label_prefix = 'ABC'

# Language localization code - both primary and sub-code (see ISO 3166-2), i.e.  en-us   es-mx
lang = 'en-us'

# The location of the code downloaded from source control without trailing backslash
version_control_dir = r'C:\VC'

# Output file name
save_results_filename = r'C:\Users\Dag.Calafell\Desktop\checked-in labels in all envs.csv'

# These are calculated from the above, change only if needed
file_name_to_inspect = 'ax' + label_prefix + lang + '.ald'
rexLabelLine = re.compile(r"^(\@' + label_prefix + r'\d+)(.+)", re.MULTILINE)
rexBranchName = re.compile(version_control_dir + r"\\([^\\]+)\\")


#########
# Logic #
#########
with open(save_results_filename, 'w', newline='') as csvfile:
    csvfile.write('\t'.join(['Branch','Label','Contents']) + '\n')

    for path, subdirs, files in os.walk(version_control_dir):
        for file in files:
            if file == file_name_to_inspect:
                full_path = os.path.join(path, file)

                # Skip hidden files
                if os.path.isfile(full_path):
                    branch_name = rexBranchName.match(full_path).group(1)

                    with open(full_path, 'r') as label_file:
                        label_file_contents = label_file.read()

                        for match in rexLabelLine.finditer(label_file_contents):
                            csvfile.write('\t'.join([branch_name, match.group(1), match.group(2)]) + '\n')
