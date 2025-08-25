if (typeof online === 'undefined')
{
	online = {};
}

if (typeof online.tacticians === 'undefined')
{
	online.tacticians = {};
}

if (typeof online.tacticians.tabletop === 'undefined')
{
	online.tacticians.tabletop = {};
}

online.tacticians.tabletop.init =
	function (node_id)
	{
		online.tacticians.tabletop.app =
			Gren.Main.init
			(
				{
					node: document.getElementById(node_id),
					flags:
						{
							url_params: online.tacticians.tabletop.get_raw_url_params(),
							local_values: online.tacticians.tabletop.get_raw_local_values()
						},
					taskPorts:
						{
							set_page_title:
								async function (str)
								{
									online.tacticians.tabletop.set_page_title(str);

									return "";
								},
							get_url_params:
								async function (str)
								{
									return online.tacticians.tabletop.get_url_params();
								},
							set_url_params:
								async function (str)
								{
									online.tacticians.tabletop.set_url_params(str);

									return "";
								},
							clear_url_params:
								async function ()
								{
									online.tacticians.tabletop.clear_url_params();

									return "";
								},
							get_local_values:
								async function (str)
								{
									return online.tacticians.tabletop.get_local_values();
								},
							set_local_values:
								async function (str)
								{
									online.tacticians.tabletop.set_local_values(str);

									return "";
								},
							clear_local_values:
								async function ()
								{
									online.tacticians.tabletop.clear_local_values();

									return "";
								}
						}
				}
			);
	};

online.tacticians.tabletop.get_local_values =
	function ()
	{
		return JSON.stringify(localStorage);
	};

online.tacticians.tabletop.get_raw_local_values =
	function ()
	{
		return localStorage;
	};

online.tacticians.tabletop.set_local_values =
	function (dict_as_str)
	{
		online.tacticians.tabletop.clear_local_values();

		var dict = JSON.parse(dict_as_str);

		for (key in dict)
		{
			localStorage.set(key, dict[key]);
		}
	};

online.tacticians.tabletop.clear_local_values =
	function ()
	{
		localStorage.clear();
	};

online.tacticians.tabletop.set_url_params =
	function (dict_as_str)
	{
		online.tacticians.tabletop.clear_url_params();

		const url = new URL(location);

		var dict = JSON.parse(dict_as_str);

		for (key in dict)
		{
			url.searchParams.set(key, dict[key]);
		}

		history.pushState({}, "", url);
	};

online.tacticians.tabletop.get_url_params =
	function ()
	{
		const url = new URL(location);

		return JSON.stringify(Object.fromEntries(url.searchParams));
	};

online.tacticians.tabletop.get_raw_url_params =
	function ()
	{
		const url = new URL(location);

		return Object.fromEntries(url.searchParams);
	};

online.tacticians.tabletop.clear_url_params =
	function ()
	{
		const url = new URL(location);

		while (url.searchParams.size > 0)
		{
			url.searchParams.delete(url.searchParams.keys().next().value);
		}

		history.pushState({}, "", url);
	};

online.tacticians.tabletop.set_page_title =
	async function (value)
	{
		document.title = value;
	};
