#include <syslog.h>
#include <stdio.h>

int main(int argc, char* argv[])
{

    openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

    FILE* file = fopen(argv[1],"a");
    if(NULL == file){
        syslog(LOG_ERR,"could not find the file");
        return 1;
    }
    fprintf(file,"%s\n",argv[2]);
    fclose(file);

    syslog(LOG_DEBUG, "Writing %s to file %s",argv[0],argv[1]);

    closelog();

    return 0;
}