<?=

	local(dl_type)			= action_param('type')
	local(svg)				= action_param('svg')
	local(filename)			= (string(action_param('filename')) != '' ? action_param('filename') | ('NCQC_Graph_' + date->format('%q')))
	local(today_file)		= date->format('%q')
	local(today_download)	= date->format('%Q')
	local(ext)				= string
	local(width)			= '1500'
	local(batik_path)		= "/usr/local/bin/batik-1.7/batik-rasterizer.jar"


	match(#dl_type) => {
	// SVG can be streamed directly back
	case('image/svg+xml')
		web_response->sendFile(#svg, #filename + '.svg', -type=#dl_type, -disposition='attachment')
	case('image/png')
		#ext = 'png'
	case('image/jpeg')
		#ext = 'jpg'
	case('application/pdf')
		#ext = 'pdf'
	case('image/pngtrans')
		#ext = 'png'
		#dl_type = 'image/png'
		#svg->replace('fill="#FFFFFF"', 'fill="none"')
	}
	// do the conversion & stream the result
	local(temp_svg_file) = file('///var/tmp/' + #filename + '.svg', file_openReadWrite, file_modeChar)
	#temp_svg_file->writeBytes(#svg->asBytes)&close

	
	local(my_process) = sys_process
	local(stdout, stderr)

	#my_process->open('/usr/bin/java', (: "-Djava.awt.headless=true", "-jar", #batik_path, "-m", #dl_type, '-bg', '0.255.255.255', '-w', #width, '-q', '.99', '-dpi', '200', #temp_svg_file->path))
	#my_process->wait
	#stdout = #my_process->read
	#stderr = #my_process->readError
	#my_process->close

	local(f) = file('///var/tmp/' + #filename + '.' + #ext)
	handle => {
		#temp_svg_file->delete
		#f->delete
	}
	#f->doWithClose => {
		web_response->sendFile(#f, #filename + "." + #ext, -type=#dl_type, -disposition='attachment')
	}
?>