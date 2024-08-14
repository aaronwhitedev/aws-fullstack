import { useState } from "react";
import { Link } from "react-router-dom";

function Nav() {
	const [openNav, setOpenNav] = useState(false);

	return (
		<nav className="flex justify-center min-h-24 p-6 bg-slate-100 border-b border-b-1 border-b-slate-300">
			<div className="flex 2xl:w-3/5 l:w-3/5 lg:w-4/5 w-full">
				<div className="flex flex-wrap w-full justify-between">
					<div className="md:w-1/4 mr-4">
						<Link to="/" className="text-2xl font-bold">
							Logo
						</Link>
					</div>

					<div className="lg:hidden md:flex md:justify-end">
						<button onClick={() => setOpenNav(!openNav)} className="flex items-center h-8 w-8 align-middle justify-center border rounded text-black-500 hover:text-black-400 text-slate-900 border-slate-900">
							<svg className={`fill-current h-3 w-3 ${openNav ? "hidden" : "block"}`} viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
								<path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z" />
							</svg>
							<svg className={`fill-current h-3 w-3 ${!openNav ? "hidden" : "block"}`} viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
								<path d="M10 8.586L2.929 1.515 1.515 2.929 8.586 10l-7.071 7.071 1.414 1.414L10 11.414l7.071 7.071 1.414-1.414L11.414 10l7.071-7.071-1.414-1.414L10 8.586z" />
							</svg>
						</button>
					</div>
					<div className={`w-full block flex-grow lg:flex lg:items-center lg:w-auto ${openNav ? "block" : "hidden"}`}>
						<div className={`flex lg:w-full text-lg align-middle m-h-10 ${openNav && "mt-4"}`}>
							<div className="flex flex-wrap md:w-4/5 xs:w-1/2 justify-end">
								<Link to="/link1" className="mr-2" onClick={() => setOpenNav(false)}>
									Link 1
								</Link>
								<Link to="/link2" className="mr-2" onClick={() => setOpenNav(false)}>
									Link 2
								</Link>
								<Link to="/link3" onClick={() => setOpenNav(false)}>
									Link 3
								</Link>
							</div>
							<div className="flex md:w-1/5 xs:w-1/2 justify-end"></div>
						</div>
					</div>
				</div>
			</div>
		</nav>
	);
}

export default Nav;
