/**
# Copyright (C) 2016 Nafiu Shaibu.
#
#
# Qemubox_logger is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your option) 
# any later version.

# Qemubox_logger is distributed in the hopes that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/

#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <chrono>
#include <ctime>

using namespace std;

int main(int argc, char **argv)
{
	ifstream input;
	ofstream output;
	
	input.open(argv[1]);
	
	/*if(const char* env_qemulog = std::getenv("QEMU_LOGS"))*/
	 output.open(argv[2], ios::app);
	
	chrono::system_clock::time_point now = chrono::system_clock::now();
	time_t now_c = chrono::system_clock::to_time_t(now);
    

	if(input.fail() && output.fail())
		exit(EXIT_FAILURE);
	else
	{
		output<<put_time(localtime(&now_c), "%F %T")<<"  ]:"<<argv[1]<<endl;
		
		output.close();
		input.close();
	}
	
	return 0;
}
