/* Close all possible open files/sockets, execute an app and then wait for it to finish or kill it before that */
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

int main(int argc, char *argv[])
{
	unsigned int	maxduration = (5*60);
	long		i, max = sysconf(_SC_OPEN_MAX);
	int		pid;

	if (argc < 2)
	{
		fprintf(stdout, "No arguments given\n");
		return 0;
	}

	/* Close down all sockets except stdout/stderr */
	close(0);
	for (i=3; i < max; i++) close(i);

	/* Be your own daddy */
	setsid();

	/* Fork it */
	pid = fork();
	if (pid == 0)
	{
		/* Child */

		/* Execute it */
		execv(argv[1], &argv[1]);

		fprintf(stdout, "Couldn't exec: %s\n", argv[0]);
	}
	else if (pid > 0)
	{
		/* Parent */

		/* Time it */
		unsigned int	howlong = 0;
		int		status;

		while (1)
		{
			/* Wait for the childs status to change */
			status = 0;
			if (waitpid(pid, &status, WNOHANG) != 0)
			{
				/* Done when it exits */
				if (WIFEXITED(status) || WIFSIGNALED(status))
				{
					/* printf("Process (%s) ran for %u/%u seconds\n", ); */
					break;
				}
			}

			if (howlong > maxduration)
			{
				kill(pid, SIGKILL);
				fprintf(stdout, "Process killed, ran too long\n");
			}

			/* We sleep for 1 second, which means we might sleep for a bit more though */
			sleep(1);
			howlong++;
		}
	}
	else
	{
		fprintf(stdout, "Couldn't fork\n");
	}

	return 0;
}

