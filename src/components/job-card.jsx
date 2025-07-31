/* eslint-disable react/prop-types */
import { Heart, MapPinIcon, Trash2Icon } from "lucide-react";
import { Button } from "./ui/button";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "./ui/card";
import { Link } from "react-router-dom";
import useFetch from "@/hooks/use-fetch";
import { deleteJob, saveJob } from "@/api/apiJobs";
import { useUser } from "@clerk/clerk-react";
import { useEffect, useState } from "react";
import { BarLoader } from "react-spinners";

const JobCard = ({
  job,
  savedInit = false,
  onJobAction= () => {},
  isMyJob = false,
}) => {
  const [saved, setSaved] = useState(savedInit);

  const { user } = useUser();

  const { loading: loadingDeleteJob, fn: fnDeleteJob } = useFetch(deleteJob, {
    job_id: job.id,
  });

  const {
    loading: loadingSavedJob,
    data: savedJob,
    fn: fnSavedJob,
  } = useFetch(saveJob);

   const handleSaveJob = async () => {
     await fnSavedJob({
       user_id: user.id,
       job_id: job.id,
     });
     onJobAction()();

    console.log(saved ? "Un-saving..." : "Saving...");
await fnSavedJob(
  { alreadySaved: saved }, // tells the API whether to insert/delete
  { user_id: user.id, job_id: job.id }
);

onJobAction(); // refreshes saved job list

     };
  

  const handleDeleteJob = async () => {
    await fnDeleteJob();
    onJobAction();
  };

  // useEffect(() => {
  //   if (savedJob !== undefined) setSaved(savedJob?.length > 0);
  // }, [savedJob]);

  useEffect(() => {
  if (savedJob !== undefined) setSaved(savedJob?.length > 0);
}, [savedJob]);


  return (
    <Card className="flex flex-col">
      {loadingDeleteJob && (
        <BarLoader className="mt-4" width={"100%"} color="#36d7b7" />
      )}
      {/* <CardHeader className="flex">
        <CardTitle className="flex justify-between font-bold">
          {job.title}
          {isMyJob && (
            <Trash2Icon
              fill="red"
              size={18}
              className="text-red-300 cursor-pointer"
              onClick={handleDeleteJob}
            />
          )}
        </CardTitle>
      </CardHeader> */}

      <CardHeader className="flex flex-row justify-between items-start">
  <CardTitle className="font-bold">{job.title}</CardTitle>

  {isMyJob && (
    <Trash2Icon
      fill="red"
      size={18}
      className="text-red-300 cursor-pointer"
      onClick={handleDeleteJob}
    />
  )}
      </CardHeader>
      
      <CardContent className="flex flex-col gap-4 flex-1">
        <div className="flex justify-between">
          {job.company && <img src={job.company.logo_url} className="h-6" />}
          <div className="flex gap-2 items-center">
            <MapPinIcon size={15} /> {job.location}
          </div>
        </div>
        <hr />
        {/* {job.description.substring(0, job.description.indexOf("."))}. */}
        {job.description.length > 150
  ? job.description.slice(0, 150) + "..."
  : job.description}
      </CardContent>
      <CardFooter className="flex gap-2">
        <Link to={`/job/${job.id}`} className="flex-1">
          <Button variant="secondary" className="w-full">
            More Details
          </Button>
        </Link>
        {!isMyJob && (

          <Button
            variant="outline"
            className="w-15"
            onClick={handleSaveJob}
            disabled={loadingSavedJob}
          >
            {saved ? (
              <Heart size={20} fill="red" stroke="red" />
            ) : (
              <Heart size={20} />
            )}
          </Button>

          

        )}
      </CardFooter>
    </Card>
  );
};

export default JobCard;


