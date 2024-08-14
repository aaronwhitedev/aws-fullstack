import React from "react";
import ReactDOM from "react-dom/client";
import { createBrowserRouter, RouterProvider, createRoutesFromElements, Route, Outlet } from "react-router-dom";

import "./index.css";
import Nav from "./Nav";
import Home from "./Home";
import ErrorPage from "./ErrorPage";

const Root = () => {
	return (
		<>
			<Nav />
			<Outlet />
		</>
	);
};

const router = createBrowserRouter(
	createRoutesFromElements(
		<Route path="/" element={<Root />} errorElement={<ErrorPage />}>
			<Route index element={<Home />} />
		</Route>
	)
);

ReactDOM.createRoot(document.getElementById("root")!).render(
	<React.StrictMode>
		<RouterProvider router={router} />
	</React.StrictMode>
);
